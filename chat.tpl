<!doctype html>
<html><head>
    <title>Push message sender</title>
</head><body>
    <em>{{status}}</em>
    <form action="/" method="post">
        <h3>Send message to {{count}} registered ids.</h3>
        <input type="text" name="msg"><button type="submit">Send</button>
    </form>
</body></html>


# navigator.push.addEventListener("push", function() { console.log("push event", arguments); }, false
PushMessageEvent
- bubbles: true
- cancelBubble: false
- cancelable: true
- clipboardData: undefined
- currentTarget: PushManager
- data: "cats cats cats"
- defaultPrevented: false
- eventPhase: 0
- path: NodeList[0]
- returnValue: true
- srcElement: PushManager
- target: PushManager
- timeStamp: 1296023244040
- type: "push"