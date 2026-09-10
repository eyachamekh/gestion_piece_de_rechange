import tensorflow as tf, os
p=os.path.join(os.path.dirname(__file__),'models','mobilenet_v2_feature_vector.tflite')
interpreter=tf.lite.Interpreter(model_path=p)
interpreter.allocate_tensors()
print('model file:',p)
for d in interpreter.get_input_details(): print('input',d['shape'],d['dtype'])
for d in interpreter.get_output_details(): print('output',d['shape'],d['dtype'])
