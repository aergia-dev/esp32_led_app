

class Protocol {
  static var map = {
    "LED_OFF": [0x01, 0x00, 0x00],
    "LED_ON": [0x01, 0x01, 0x00],
    "BRIGHTNESS": [0x01, 0x02, 0x00],
    //"BRIGHTER": [0x01, 0x03, 0x00],
    "CHANGE_COLOR": [0x01, 0x04, 0x03],
    "SAVE_COLOR_FLASH": [0x01, 0x05, 0x03],
    "RESET": [0x01, 0x06, 0x00],
    "READ_CURRENT_COLOR": [0x01, 0x07, 0x00],
    "READ_LIGHTONOFF": [0x01, 0x08, 0x00],
  };
}