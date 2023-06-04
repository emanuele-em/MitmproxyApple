# MitmproxyApple
First tests with network extension to implement mitmproxy transparent proxy with swift on macos

## File Structure

### MVC pattern:

* *MitmproxyApple/Controller/Viewcontroller.swift*: where there is button management, event triggering, and GUI logic
* *MitmproxyApple/Model/Proxy.swift*: data model and behavior (the actual brain)
* *MitmproxyApple/View/Base.lproj/Main.storyboard*: storyboard
* *MitmproxyAppleExtension/AppProxyProvider.swift*: The protocol of the extension and its cycle (where the packets are)

## Screenshots

### First start
<img width="267" alt="Screenshot 2023-06-04 at 15 41 37" src="https://github.com/emanuele-em/MitmproxyApple/assets/100081325/d085790f-f0f5-497b-bc9e-80b22edbbb53">

### Before run
<img width="487" alt="Screenshot 2023-06-04 at 15 42 36" src="https://github.com/emanuele-em/MitmproxyApple/assets/100081325/3a045252-a96b-4a00-820e-d64295025797">

### First run
<img width="265" alt="Screenshot 2023-06-04 at 15 42 48" src="https://github.com/emanuele-em/MitmproxyApple/assets/100081325/68d035e5-b859-4183-9ea5-8c8dbe13a4bb">

### After run
<img width="487" alt="Screenshot 2023-06-04 at 15 42 57" src="https://github.com/emanuele-em/MitmproxyApple/assets/100081325/66e6a830-0489-4bcb-8237-8daf859b30ba">
