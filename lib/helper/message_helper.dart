import 'package:cognigy_flutter_client/models/message_model.dart';

CognigyMessage processCognigyMessage(dynamic cognigyResponse) {

  if (cognigyResponse['type'] == 'output') {
    // check for simple text
    if (cognigyResponse['data']['text'] != null) {
      return new CognigyMessage('text', cognigyResponse['data']['text'], null);
    }

    // check for quick replies
    if (cognigyResponse['data']['data']['_cognigy']['_webchat'] != null) {
      String text =
          cognigyResponse['data']['data']['_cognigy']['_webchat']['message'];
      List quickReplies = cognigyResponse['data']['data']['_cognigy']
          ['_webchat']['quick_replies'];

      print('TEXT: $text');
      print('QUICK REPLIES: $quickReplies');

      return new CognigyMessage('quick_replies', text, quickReplies);
    }
  }
}
