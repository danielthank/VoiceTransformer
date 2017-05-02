clear;
close all;
[d, sr] = audioread('trump.wav');
%d = d(:, 1) + d(:, 2);
d = resample(d, 8000, sr);
sr = 8000;
%t = 1/8000 * (1:length(d))';
%d = d .* cos(2 * pi * 1000 * t);
%player = audioplayer(d(1:20000), sr);
%playblocking(player);

player = audioplayer(d(100000:200000), sr);
%playblocking(player);
player = audioplayer(resample(pvoc(d(100000:200000), 0.75, 64, sr), 3, 4), sr);
playblocking(player);

%o = [pvoc(d(1:500000,1), 0.75, 1024), pvoc(d(1:500000,2), 0.75, 1024)];
%o = resample(o, 3, 4);
%sound(o, sr);
