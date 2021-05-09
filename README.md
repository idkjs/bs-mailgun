# bs-mailgun
[mailgun-js][mailgun-js] bucklescript bindings.

[Mailgun][mailgun] is a cloud-based email service for sending, receiving and tracking email sent through
your websites and applications. [mailgun-js][mailgun-js] is a node module for interacting with [Mailgun's api][mailgun-api].
This bucklescript library is a binding for [mailgun-js][mailgun-js].

## Installation
```bash
npm install @piq9117/bs-mailgun
```
### bsconfig
```json
  ...

  "bs-dependencies": [
    "@piq9117/bs-mailgun"
  ]
  ...
```

# Usage

### Sending Mail
```ocaml
let mailgunKeys =
  Mailgun.mailgunReq
    ~apiKey:"YOUR API KEY"
    ~domain:"YOUR DOMAIN"

let mailgun = Mailgun.mailgun req

let emailData =
  Mailgun.emailData
    ~from:"Excited User <me@samples.mailgun.org>"
    ~to_:"serobnic@mail.ru"
    ~subject:"Hello"
    ~text:"Testing some Mailgun awesomeness!"
    
let messages = Mailgun.Message.messages mailgun

let sendMail =
  let open Belt_Result in
  Mailgun.Message.send messages emailData (fun s ->
    match s with
    | Ok o -> Js.log o
    | Error e -> Js.log e 
  )
```
[More examples on how to use this bindings library](./docs/howto.md)

[mailgun-js]:http://bojand.github.io/mailgun-js/#/
[mailgun]:https://www.mailgun.com/
[mailgun-api]:https://documentation.mailgun.com/en/latest/api_reference.html
