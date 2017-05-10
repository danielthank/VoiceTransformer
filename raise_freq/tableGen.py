from operator import mul
from math import degrees, atan
#import numpy as np

scale = 2**6
n = 8
#lenScale = 1
#angle = [2880.0, 1700.0, 898.0, 456.0, 229.0, 115.0, 57.0, 29.0]
print(round(scale * reduce(mul, [1/(1+4**-i)**0.5 for i in range(n)])))
#for i in range(0,n):
#    lenScale *= np.cos(angle[i]/256/180*np.pi)
#print(lenScale)

print([round(scale * degrees(atan(2**-i))) for i in range(n)])
