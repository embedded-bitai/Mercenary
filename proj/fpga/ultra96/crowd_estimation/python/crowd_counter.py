# In[1]:
import cv2
import imutils
from imutils.object_detection import non_max_suppression
import numpy as np
import requests
import time
import base64
from matplotlib import pyplot as plt
from IPython.display import clear_output

# In[2]:
URL = "http://industrial.api.ubidots.com"
INDUSTRIAL_USER = True
TOKEN = "YOUR_TOKEN" 
DEVICE = "camera"  
VARIABLE = "people" 

# HOG cv2 object
hog = cv2.HOGDescriptor()
hog.setSVMDetector(cv2.HOGDescriptor_getDefaultPeopleDetector())

# In[3]:
def detector(image):
   rects, weights = hog.detectMultiScale(image, winStride=(4, 4), padding=(8, 8), scale=1.05)
   for (x, y, w, h) in rects:
       cv2.rectangle(image, (x, y), (x + w, y + h), (0, 0, 255), 2)
   rects = np.array([[x, y, x + w, y + h] for (x, y, w, h) in rects])
   result = non_max_suppression(rects, probs=None, overlapThresh=0.7)
   return result

# In[4]:
def buildPayload(variable, value):
   return {variable: {"value": value}}

# In[5]:
def send(token, device, variable, value, industrial=True):
   # build endpoint
   url = URL
   url = "{}/api/v1.6/devices/{}".format(url, device)
   payload = buildPayload(variable, value)
   headers = {"X-Auth-Token": token, "Content-Type": "application/json"}
   attempts = 0
   status = 400
   # handle bad requests
   while status >= 400 and attempts <= 5:
       req = requests.post(url=url, headers=headers, json=payload)
       status = req.status_code
       attempts += 1
       time.sleep(1)
   return req

# In[6]:
def record(token, device, variable, sample_time=5):
   print("recording")
   camera = cv2.VideoCapture(0)
   init = time.time()
   # ubidots sample limit
   if sample_time < 1:
       sample_time = 1
   while(True):
       print("cap frames")
       ret, frame = camera.read()
       frame = imutils.resize(frame, width=min(400, frame.shape[1]))
       result = detector(frame.copy())
       # show frame with bounding rectangle for debugging/ optimisation
       for (xA, yA, xB, yB) in result:
           cv2.rectangle(frame, (xA, yA), (xB, yB), (0, 255, 0), 2)
       plt.imshow(frame)
       plt.show()
       # sends results
       if time.time() - init >= sample_time:
           print("sending result")
           send(token, device, variable, len(result))
           init = time.time()
   camera.release()
   cv2.destroyAllWindows()

# In[7]:
def main():
   record(TOKEN, DEVICE, VARIABLE)

# In[8]:
if __name__ == '__main__':
   main() 
