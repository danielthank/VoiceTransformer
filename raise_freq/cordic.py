import sys
import numpy as np

def toPolar(x,y,precision):
    angle = [11520, 6801, 3593, 1824, 916, 458, 229, 115, 57,
            29, 14, 7, 4, 2, 1]
    angle2 = [2880.0, 1700.0, 898.0, 456.0, 229.0, 115.0, 57.0, 29.0]
    x_new = 0
    y_new = 0
    angleSum = 0
    quardrant = 0
    lenScale = 1
    angleScale = 64.

    #x *= 1024
    #y *= 1024

    if y == 0:
        if x > 0:
            return 0, x
        else:
            return 180, -x
    else:

        if x<0 and y>0:
            quardrant = 2
            x = -x
        elif x<0 and y<0:
            quardrant = 3
            x = -x

        for i in range(0,precision):
            lenScale *= np.cos(angle2[i]/angleScale/180*np.pi)
            if y>0:
                x_new = x + (y/np.power(2,i))
                y_new = -(x/np.power(2,i)) + y
                x = x_new
                y = y_new
                angleSum += angle2[i]
            else:
                x_new = x - (y/np.power(2,i))
                y_new = (x/np.power(2,i)) + y
                x = x_new
                y = y_new
                angleSum -= angle2[i]
            print (i)
            print (angleSum)
            print (x)
            print (y)
            print ()
        if quardrant == 2:
            return 180 - angleSum/angleScale, x*lenScale
        elif quardrant == 3:
            return -180 - angleSum/angleScale, x*lenScale
        else:
            return angleSum/angleScale, x*lenScale

def toRect(r,theta,precision):
    angle = [11520, 6801, 3593, 1824, 916, 458, 229, 115, 57,
            29, 14, 7, 4, 2, 1]
    angle2 = [2880.0, 1700.0, 898.0, 456.0, 229.0, 115.0, 57.0, 29.0]
    x = 0.
    y = 0.
    quardrant = 0
    angleSum = 0
    lenScale = 1
    angleScale = 64

    if theta == 0:
        return r, 0
    elif theta == 180 or theta == -180:
        return -r, 0
    else:

        if theta>90 and theta<180:
            quardrant = 2
            theta = 180 - theta
        elif theta<-90 and theta>-180:
            quardrant = 3
            theta = -(180 + theta)
        for i in range(0,precision):
            lenScale *= np.cos(angle2[i]/angleScale/180*np.pi)

        x = r*lenScale
        angleSum = theta*angleScale
        print(angleSum)
        print("x:"+str(x)+" r:"+str(r)+" lenScale:"+str(lenScale)
                +" lenScale*64:" + str(lenScale*64))
        print(y)
        print ()

        for i in range(0,precision):
            if angleSum>0:
                #counter clockwise
                x, y = x - (y/np.power(2,i)), (x/np.power(2,i)) + y
                angleSum -= angle2[i]
            else:
                x, y = x + (y/np.power(2,i)), -(x/np.power(2,i)) + y
                angleSum += angle2[i]
            print (i)
            print (angleSum)
            print (x)
            print (y)
            print ()
        if quardrant == 2:
            return -x, y
        elif quardrant == 3:
            return -x, y
        else:
            return x, y

if len(sys.argv)<5:
    message = "Usage: " + sys.argv[0] + "[rect(r)/polar(p)] [x/r] [y/theta] [precision(1~15)]"
    print (message)
    sys.exit()

mode = sys.argv[1]
precision = int(sys.argv[4])

if (mode == "r"):
    x = float(sys.argv[2])
    y = float(sys.argv[3])
    theta, r = toPolar(x,y,precision)

    print ("Calculated angle of ("+str(x)+", "+str(y)+") = "+str(theta))
    print ("Calculated radius of ("+str(x)+", "+str(y)+") = "+str(r))
    ansTheta = np.arctan2(y,x)*180/np.pi
    ansR = np.power(np.power(x,2)+np.power(y,2),0.5)
    print ("Angle of ("+str(x)+", "+str(y)+") from numpy = "+str(ansTheta))
    print ("Radius of ("+str(x)+", "+str(y)+") from numpy = "+str(ansR))
elif (mode == "p"):
    r = float(sys.argv[2])
    theta = float(sys.argv[3])
    x, y = toRect(r,theta,precision)

    print ("Calculated x of ("+str(r)+", "+str(theta)+") = "+str(x))
    print ("Calculated y of ("+str(r)+", "+str(theta)+") = "+str(y))
    ansX = r*np.cos(theta*np.pi/180)
    ansY = r*np.sin(theta*np.pi/180)
    print ("x of ("+str(r)+", "+str(theta)+") from numpy = "+str(ansX))
    print ("y of ("+str(r)+", "+str(theta)+") from numpy = "+str(ansY))


