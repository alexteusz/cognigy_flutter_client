# Cognigy Demo - Flutter App

<div style="width: 100%; text-align: center;"><img src="./assets/images/logo.png" width="50%"></div>

This project implements a demo mobile application to show how to connect your [Cognigy.AI](https://cognigy.com/) project to a Flutter app. Therefore, the user has to insert the [Socket Endpoint Configuration](https://docs.cognigy.com/docs/deploy-a-socket-endpoint)into the configuration dialog. After that, the application will automatically connect to Cognigy; the status is displayed by a <span style="color: green">green</span> or <span style="color: red">red</span> button on the top-right corner of the screen.

<img src="./docs/images/demo.png">


## Todo: 

- [ ] Add Push Notifications for enabling notify API usage
- [x] Store socket url and url token into file to make is persitent over time
- [ ] Add list message support
- [ ] Add various styles which the can choose in the settings