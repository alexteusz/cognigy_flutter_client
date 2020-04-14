import 'package:cognigy_flutter_client/models/message_model.dart';

ChatMessage processCognigyMessage(dynamic cognigyResponse) {

  if (cognigyResponse['type'] == 'output') {
    // check for simple text
    if (cognigyResponse['data']['text'] != null) {
      return new ChatMessage('text', cognigyResponse['data']['text'], null);
    }

    // check for quick replies
    if (cognigyResponse['data']['data']['_cognigy']['_webchat']['message']['quick_replies'] != null) {
      String text =
          cognigyResponse['data']['data']['_cognigy']['_webchat']['message']['text'];
      
      List quickReplies = cognigyResponse['data']['data']['_cognigy']['_webchat']['message']['quick_replies'];

      return new ChatMessage('quick_replies', text, quickReplies);
    }

    // check for image
    if (cognigyResponse['data']['data']['_cognigy']['_webchat']['message']['attachment']['type'] == 'image') {
      String url = cognigyResponse['data']['data']['_cognigy']['_webchat']['message']['attachment']['payload']['url'];

      return new ChatMessage('image_attachment', url, null);
    }

    // check for gallery
    if (cognigyResponse['data']['data']['_cognigy']['_webchat']['message']['attachment']['type'] == 'template' && cognigyResponse['data']['data']['_cognigy']['_webchat']['message']['attachment']['payload']['template_type'] == 'generic') {
      List galleryItems = cognigyResponse['data']['data']['_cognigy']['_webchat']['message']['attachment']['payload']['elements'];

      return new ChatMessage('gallery', '', galleryItems);
    }

    if (cognigyResponse['data']['data']['_cognigy']['_webchat']['message']['attachment']['type'] == 'video') {
      String url = cognigyResponse['data']['data']['_cognigy']['_webchat']['message']['attachment']['payload']['url'];

      return new ChatMessage('video', url, null);
    }

    if (cognigyResponse['data']['data']['_cognigy']['_webchat']['message']['attachment']['type'] == 'video') {

    }

    // check for buttons
    if (cognigyResponse['data']['data']['_cognigy']['_webchat']['message']['attachment']['type'] == 'template' && cognigyResponse['data']['data']['_cognigy']['_webchat']['message']['attachment']['payload']['template_type'] == 'button') {
      String buttonText = cognigyResponse['data']['data']['_cognigy']['_webchat']['message']['attachment']['payload']['text'];
      List buttons = cognigyResponse['data']['data']['_cognigy']['_webchat']['message']['attachment']['payload']['buttons'];

      return new ChatMessage('buttons', buttonText, buttons);
    }
  }
}
