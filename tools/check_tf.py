import sys
try:
    import tensorflow as tf
    print('tensorflow', tf.__version__)
except Exception as e:
    try:
        import tflite_runtime.interpreter as tflite
        print('tflite_runtime')
    except Exception as e2:
        print('NO_TF')
        # print exceptions for debugging
        # print('tf_error', e)
        # print('tflite_error', e2)
