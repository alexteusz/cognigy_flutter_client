  
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:cognigy_flutter_client/cognigy/socket_service.dart';

// Create an Instance of the class to use it everywhere.
class DependencyInjection {
  Injector initialise(Injector injector) {
    injector.map<SocketService>((i) => SocketService(), isSingleton: true);
    return injector;
  }
}