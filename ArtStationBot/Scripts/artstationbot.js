// The main class
function ArtStationBot() {}

// Alias
var ASB = ArtStationBot
ASB.messageHandlerName = "asb"
ASB.msg = webkit.messageHandlers[ASB.messageHandlerName]

// Functions

ASB.prototype.greet = function() {
    ASB.msg.postMessage({"id": "greet", status: true, "msg": "hello world"})
}

ASB.prototype.init = function() {
    ASB.msg.postMessage({"id": "document-url", "status": true, "value": document.URL})
}

ASB.prototype.getCount = function() {
    ASB.msg.postMessage({"id": "main-nav-len", "status": true, "value": document.querySelector('.fixed-main-nav').classList.value.length})
}

ASB.prototype.signIn = function(username, password) {
    if (username.isEmpty() || password.isEmpty()) { ASB.msg.postMessage({"id": "sign-in", "status": false, "msg": "Arguments cannot be empty"}); return; }
    const btn = document.querySelector("a[href='/users/sign_in'] i")
    if (btn) {
        btn.click()
        document.querySelector("#new_user input.email").value = username
        document.querySelector("#new_user input.password").value = password
        document.querySelector("#new_user button[type='submit']").click()
    } else {
        if (this.internal.isSignedIn()) {
            ASB.msg.postMessage({"id": "sign-in", "status": true, "msg": "Already signed-in"})
        } else {
            ASB.msg.postMessage({"id": "sign-in", "status": false, "msg": "Error getting sign-in button node"})
        }
    }
}

ASB.prototype.isSignedIn = function() {
    ASB.msg.postMessage({"id": "is-signed-in?", "status": true, "value": this.internal.isSignedIn()})
}

ASB.prototype.internal = {
    "isSignedIn": function () {
        return window.user_id != null && typeof window.user_id === "number"
    }
}

// Extensions
String.prototype.isEmpty = function() { return this.length == 0 }

var asb = new ASB()
asb.greet()
