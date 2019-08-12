var asb = {};
asb.messageHandlerName = "asb";
asb.msg = webkit.messageHandlers[asb.messageHandlerName];

String.prototype.isEmpty = function() { return this.length == 0 }

asb.internal = {
    "isSignedIn": function () {
        return window.user_id != null && typeof window.user_id === "number"
    }
}

asb.greet = function() {
    asb.msg.postMessage({"id": "greet", status: true, "msg": "hello world >>>"})
}

asb.init = function() {
    asb.msg.postMessage({"id": "document-url", "status": true, "value": document.URL});
}

asb.getCount = function() {
    asb.msg.postMessage({"id": "main-nav-len", "status": true, "value": document.querySelector('.fixed-main-nav').classList.value.length});
}

asb.signIn = function(data) {
    var username = data.username
    var password = data.password
    if (username.isEmpty() || password.isEmpty()) {
        asb.msg.postMessage({"id": "sign-in", "status": false, "msg": "Arguments cannot be empty"});
        return;
    }
    const btn = document.querySelector("a[href='/users/sign_in'] i");
    if (btn) {
        btn.click();
        document.querySelector("#new_user input.email").value = username;
        document.querySelector("#new_user input.password").value = password;
        document.querySelector("#new_user button[type='submit']").click();
    } else {
        if (asb.internal.isSignedIn()) {
            asb.msg.postMessage({"id": "sign-in", "status": true, "msg": "Already signed-in"});
        } else {
            asb.msg.postMessage({"id": "sign-in", "status": false, "msg": "Error getting sign-in button node"});
        }
    }
}

asb.isSignedIn = function() {
    asb.msg.postMessage({"id": "is-signed-in?", "status": true, "value": asb.internal.isSignedIn()});
}

asb.sendMessage = function(data) {
    try {
        document.querySelector("nav.navbar-artist-profile button[ng-authorized-click='showUserMessageModal()']").click();
        var textarea = document.querySelector("form[name=messageForm] textarea[ng-model='messageBody']");
        var cb = document.querySelector("input[value='general']");  // Find radio button with General and select it
        if (cb) { cb.checked = true; }
        textarea.value = data.msg;
        textarea.dispatchEvent(new Event("change"));  // Trigger field processing so that angular js adds the right directives
        //document.querySelector("form[name=messageForm] div.btn-toolbar button[type='submit']").click();  // Send message  // TODO: uncomment
        asb.msg.postMessage({"id": "send-message", "status": true, "msg": data.msg});
    } catch (e) {
        asb.msg.postMessage({"id": "send-message", "status": false});
    }
}

asb.hello = function(name) {
    asb.msg.postMessage({"id": "greet", "status": true, "msg": "hello to " + name});
}

//asb.greet()
