import scipy.io.wavfile as wavfile
import numpy as np
import sounddevice as sd
from IPython.display import Audio

def main():
    sr, data = wavfile.read('lemon.wav')
    ratio = sr / 8000
    print(data.dtype)
    print((data ** 2).mean())
    data = np.interp(np.arange(0, len(data), ratio), np.arange(0, len(data)), data).astype('int16')
    print((data ** 2).mean())
    print(data.dtype)
    sr = 8000
    Audio(data, rate=sr)
    # sd.play(data/1000, sr, blocking=True)

if __name__ == '__main__':
    main()
