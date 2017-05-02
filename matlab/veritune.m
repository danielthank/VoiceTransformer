function [outputVector] = veritune(inputVector, st)
%scaling

step = 2*st;

%pitch scaling factor
alpha = 2*step;

%space between windows, they have as 256
hop = 256;

hopOut = round(alpha*hop);

x = inputVector;

windowSize = 1024;

% Hanning window for overlap-add
wn = hann(windowSize*2+1);
wn = wn(2:2:end); 


%---------------------First part: creating frams----------------------------------------
%outputs vectorFrames and num_slices

%Max number of slices that can be obtained: Rounded! (length of input -
%window size) / hop

num_slices = floor((length(x) - windowSize) / hop);

% local changing of the source file to truncate and make sure only integer # of hop
x = x(1:(((num_slices*hop)) + windowSize));

vectorFrames = zeros(1020,1024);

% Get vectorFrames
for index = 1:num_slices

    indexTimeStart = (index-1)*hop + 1;
    indexTimeEnd = (index-1)*hop + windowSize;

    vectorFrames(index,:) = x(indexTimeStart: indexTimeEnd);

end 

outputy = zeros(1020,1024);
% Initialize cumulative phase
phaseCumulative = 0;

% Initialize previous frame phase
previousPhase = 0;

for index=1:num_slices
%ANALYSIS
%get current frame
currentFrame = vectorFrames(index,:);

%window the frame!
currentFrameWindowed = currentFrame .* wn' / sqrt(((windowSize/hop)/2));

%fft
currentFrameWindowedFFT = fft(currentFrameWindowed);

%get magnitude
magFrame = abs(currentFrameWindowedFFT);

 phaseFrame = angle(currentFrameWindowedFFT);

% Get the phase difference
deltaPhi = phaseFrame - previousPhase;
previousPhase = phaseFrame;

% Remove the expected phase difference
deltaPhiPrime = deltaPhi - hop * 2*pi*(0:(windowSize-1))/windowSize;

% Map to -pi/pi range
deltaPhiPrimeMod = mod(deltaPhiPrime+pi, 2*pi) - pi;

% Get the true frequency
trueFreq = 2*pi*(0:(windowSize-1))/windowSize + deltaPhiPrimeMod/hop;

% Get the final phase
phaseCumulative = phaseCumulative + hopOut * trueFreq;   

    
outputFrame = real(ifft(magFrame .* exp(1i*phaseCumulative)));

outputy(index,:) = outputFrame .* wn' / sqrt((windowSize/hopOut)/2);

end


%FINALIZE
	
%--------------------Second part: fusing the frames together------------------------------
%inputs: frameMatrix, has all of the frames
%		  hop
%outputs: vectorTime:vector from adding frames

sizeMatrix = size(outputy);

% Get number of frames
num_frames = sizeMatrix(1);

% Get size of each frame
size_frames = sizeMatrix(2);

% init
timeIndex = 1;
vectorTime = zeros(num_frames*hopOut-hopOut+size_frames,1);

% Loop for every fram and operlap-add
for index=1:num_frames - 1
    vectorTime(timeIndex:timeIndex+size_frames-1) = vectorTime(timeIndex:timeIndex+size_frames-1) + outputy(index,:)';

    timeIndex = timeIndex + hopOut;

end

outputVector = vectorTime(1:2:end);

%x(1:2:size(x,1));
return