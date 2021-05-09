type mailgunClient

type mailgunReq =
  { apiKey : string
  ; domain : string
  } [@@bs.deriving abstract]

external mailgunExt
  : mailgunReq
    -> mailgunClient
  = "mailgun-js" [@@bs.module]

  let mailgun
      (req : mailgunReq)
    : mailgunClient
    = mailgunExt req

type emailData =
  { from : string
  ; to_ : string [@bs.as "to"]
  ; subject : string
  ; text : string
  } [@@bs.deriving abstract]


module Callback = struct
  type nullableError = Js.Exn.t Js.Nullable.t
  type 'a jsCallback = Js.Exn.t Js.Nullable.t -> 'a -> unit
  type 'a callback = ('a, nullableError) Belt_Result.t -> unit

  let handleCallbackImpl
      (l : Js.Exn.t Js.Nullable.t -> ('a, nullableError) Belt_Result.t)
      (r : 'a -> ('a, nullableError) Belt_Result.t)
      (f : 'a callback)
      (err : nullableError)
      (value : 'a) =
    match Js.Nullable.isNullable err with
    | true -> f @@ r value
    | false -> f @@ l err

  let handleCallback (cb : 'a callback)
    = handleCallbackImpl
      (fun l -> Belt_Result.Error l)
      (fun r -> Belt_Result.Ok r)
      cb
end

module Message = struct
  type t
  type body = Js.Json.t

  external messagesExt
    : mailgunClient
      -> t
    ="messages" [@@bs.send]

    let messages
        (mg : mailgunClient)
      : t
      = messagesExt mg

  external sendExt
    : t
      -> emailData
      -> body Callback.jsCallback
      -> unit
    = "send" [@@bs.send]

    let send
        (m : t)
        (e : emailData)
        (cb : body Callback.callback)
      : unit
      = sendExt m e (Callback.handleCallback cb)

  external sendMimeExt
    : t
      -> emailData
      -> body Callback.jsCallback
      -> unit
    = "sendMime" [@@bs.send]

    let sendMime
        (m : t)
        (e : emailData)
        (cb : body Callback.callback)
      = sendMimeExt m e (Callback.handleCallback cb)
end

module MailingList = struct
  type t
  type body
  type createReq =
    { address : string
    ; name : string
    ; description : string
    ; access_level : string
    } [@@bs.deriving abstract]

  external listsExt
    : mailgunClient
      -> ?aliasAddress:string
      -> t
    = "lists" [@@bs.send]

    let lists
        (m : mailgunClient)
        ?aliasAddress:(e : string option)
        ()
      = listsExt m ~aliasAddress:(Belt_Option.mapWithDefault e "" Helpers.id)

  external infoExt
    : t
      -> body Callback.jsCallback
      -> unit
    = "info" [@@bs.send]

    let info
        (l : t)
        (cb : body Callback.callback)
      : unit
      = infoExt l (Callback.handleCallback cb)

  external createExt
    : t
      -> createReq
      -> body Callback.jsCallback
      -> unit
    = "create" [@@bs.send]

    let create
        (l : t)
        (c : createReq)
        (cb : body Callback.callback)
      = createExt l c (Callback.handleCallback cb)

end

module MailingListMembers = struct
  type mailingListMembers
  type members
  type body
  type memberReq =
    { memberAddress : string [@bs.as "address"]
    ; name : string
    ; vars : Js.Json.t
    ; subscribed : bool
    ; upsert : bool
    } [@@bs.deriving abstract]

  external membersExt
    : MailingList.t
      -> unit
      -> mailingListMembers
    = "members" [@@bs.send]

    let members (m : MailingList.t) = membersExt m ()

  external createMembersExt
    : mailingListMembers
      -> memberReq
      -> body Callback.jsCallback
      -> unit
    = "create" [@@bs.send]

    let createMember
        (c : mailingListMembers)
        (m : memberReq)
        (cb : body Callback.callback)
      : unit
      = createMembersExt c m (Callback.handleCallback cb)

  external memberListExt
    : mailingListMembers
      -> members Callback.jsCallback
      -> unit
    = "list" [@@bs.send]

    let memberList
        (ml : mailingListMembers)
        (cb : members Callback.callback)
      : unit
      = memberListExt ml (Callback.handleCallback cb)
end

module Domain = struct
  type t
  type body

  type spam_action
    = Disabled
    | Block
    | Tag

  let spamActionToString : spam_action -> string = function
    | Disabled -> "disabled"
    | Block -> "block"
    | Tag -> "tag"

  type dkim_key_size
    = High
    | Low

  let dkimKeySizeToInt : dkim_key_size -> int = function
    | Low -> 1024
    | High -> 2048

  type createReq =
    { name : string
    ; smtp_password : string
    ; spam_action : spam_action
    ; wildcard : bool
    ; force_dkim_authority : bool
    ; dkim_key_size : dkim_key_size
    ; ips : string list
    }

  type createReqFfi =
    { name : string
    ; smtp_password : string
    ; spam_action : string
    ; wildcard : bool
    ; force_dkim_authority : bool
    ; dkim_key_size : int
    ; ips : string list
    } [@@bs.deriving abstract]

  external domainsExt
    : mailgunClient
      -> ?domain:string
      -> unit
      -> t
    = "domains" [@@bs.send]

    let domains
        (mg : mailgunClient)
        ?domain:(d : string option)
        ()
      : t
      = domainsExt mg ~domain:(Belt_Option.mapWithDefault d "" Helpers.id) ()

  external listExt
    : t
      -> body Callback.jsCallback
      -> unit
    = "list" [@@bs.send]

    let list
        (m : t)
        (cb : body Callback.callback)
      : unit
      = listExt m (Callback.handleCallback cb)

  external infoExt
    : t
      -> body Callback.jsCallback
      -> unit
    = "info" [@@bs.send]

    let info
        (mg : mailgunClient)
        ~domain:(d : string)
        (cb : body Callback.callback)
      : unit
      = infoExt (domains mg ~domain:d ()) (Callback.handleCallback cb)

  external createExt
    : t
      -> createReqFfi
      -> body Callback.jsCallback
      -> unit
    = "create" [@@bs.send]

    let create
        (m : t)
        (c : createReq)
        (cb : body Callback.callback)
      : unit
      = createExt m
        (createReqFfi
           ~name:c.name
           ~spam_action:(spamActionToString c.spam_action)
           ~smtp_password:c.smtp_password
           ~wildcard:c.wildcard
           ~force_dkim_authority:c.force_dkim_authority
           ~dkim_key_size:(dkimKeySizeToInt c.dkim_key_size)
           ~ips:c.ips
        )
        (Callback.handleCallback cb)
end

module Credentials = struct
  type t
  type body
  type createReq =
    { login : string
    ; password : string
    }

  type createReqFfi =
    { login :string
    ; password : string
    } [@@bs.deriving abstract]

  external credentialsExt
    : Domain.t
      -> ?login:string
      -> unit
      -> t
    = "credentials" [@@bs.send]

    let credentials
        (d : Domain.t)
        ?login:(l : string option)
        ()
      : t
      = credentialsExt d ~login:(Belt_Option.mapWithDefault l "" Helpers.id) ()

  external listExt
    : t
      -> body Callback.jsCallback
      -> unit
    = "list" [@@bs.send]

    let list
        (m : t)
        (cb : body Callback.callback)
      : unit
      = listExt m (Callback.handleCallback cb)

  external createExt
    : t
      -> createReqFfi
      -> body Callback.jsCallback
      -> unit
    = "create" [@@bs.send]

    let create
        (m : t)
        (c : createReq)
        (cb : body Callback.callback)
      : unit
      = createExt m
        (createReqFfi
           ~login:c.login
           ~password:c.password
        )
        (Callback.handleCallback cb)

  external deleteExt
    :  t
      -> body Callback.jsCallback
      -> unit
    = "delete" [@@bs.send]

    let delete
        (m : t)
        (cb : body Callback.callback)
      : unit
      = deleteExt m (Callback.handleCallback cb)
end

module Tracking = struct
  type t
  type body
  type openTracking
  type clickTracking
  type unsubscribeTracking

  external trackingExt
    : Domain.t
      -> unit
      -> t = "tracking" [@@bs.send]

  let tracking (d : Domain.t) = trackingExt d ()

  external infoExt
    : t
      -> body Callback.jsCallback
      -> unit
    = "info" [@@bs.send]

    let info
        (m : t)
        (cb : body Callback.callback)
      = infoExt m (Callback.handleCallback cb)

  external openExt : t -> unit -> openTracking = "open" [@@bs.send]

  let openTracking (m : t) = openExt m ()

  type isActive
    = Yes
    | No
    | HtmlOnly

  type activeAttribute = { active : string } [@@bs.deriving abstract]

  let isActiveToAbstract : isActive -> activeAttribute =
    let createRec s = activeAttribute ~active:s in
    function
    | Yes -> createRec "yes"
    | No -> createRec "no"
    | HtmlOnly -> createRec "htmlonly"

  external updateOpenTrackingExt
    : openTracking
      -> activeAttribute
      -> body Callback.jsCallback
      -> unit
    = "update" [@@bs.send]

    let updateOpenTracking
        (o : openTracking)
        (a : isActive)
        (cb : body Callback.callback)
      = updateOpenTrackingExt o (isActiveToAbstract a) (Callback.handleCallback cb)

  external clickExt : t -> unit -> clickTracking = "click" [@@bs.send]

  let clickTracking (m : t) : clickTracking = clickExt m ()

  external updateClickTrackingExt
    : clickTracking
      -> activeAttribute
      -> body Callback.jsCallback
      -> unit
    = "update" [@@bs.send]

    let updateClickTracking
        (c : clickTracking)
        (a : isActive)
        (cb : body Callback.callback)
      = updateClickTrackingExt c (isActiveToAbstract a) (Callback.handleCallback cb)

  external unsubscribeExt
    : t
      -> unit
      -> unsubscribeTracking
    = "unsubscribe" [@@bs.send]

    let unsubscribeTracking (m : t) : unsubscribeTracking = unsubscribeExt m ()

  (* subscriptionAttr will be used by the user *)
  type subscriptionAttr =
    { active : bool
    ; html_footer : string option
    ; text_footer : string option
    }

  (* subscriptionAttrAbs is hidden from the consumer of this lib and is
     only used for interop with json.*)
  type subscriptionAttrAbs =
    { active : bool
    ; html_footer : string
    ; text_footer : string
    } [@@bs.deriving abstract]

  let subAttrToAbs (s : subscriptionAttr) : subscriptionAttrAbs =
    let open Belt_Option in
    subscriptionAttrAbs
      ~active:s.active
      ~text_footer:(mapWithDefault s.text_footer "" Helpers.id)
      ~html_footer:(mapWithDefault s.html_footer "" Helpers.id)

  external updateSubscriptionExt
    : unsubscribeTracking
      -> subscriptionAttrAbs
      -> body Callback.jsCallback
      -> unit
    = "update" [@@bs.send]

    let updateSubscription
        (c : unsubscribeTracking)
        (s : subscriptionAttr)
        (cb : body Callback.callback)
      = updateSubscriptionExt c (subAttrToAbs s) (Callback.handleCallback cb)
end

module Complaints = struct
  type t
  type body

  type attr =
    { address : string }

  type attrAbs =
    { address : string  } [@@bs.deriving abstract]

  let attrToAbs (a : attr) : attrAbs =
    attrAbs
      ~address:a.address

  external complaintsExt
    : mailgunClient
      -> ?address:string
      -> t
    = "complaints" [@@bs.send]

    let complaints
        (m : mailgunClient)
        ?address:(a: string option)
        ()
      : t
      = complaintsExt
        m
        ~address:(Belt_Option.mapWithDefault a "" Helpers.id)

  external listExt
    : t
      -> body Callback.jsCallback
      -> unit
    = "list" [@@bs.send]

    let list
        (m : t)
        (cb : body Callback.callback)
      = listExt m (Callback.handleCallback cb)


  external createExt
    : t
      -> attrAbs
      -> body Callback.jsCallback
      -> unit
    = "create" [@@bs.send]

    let create
        (m : t)
        (a : attr)
        (cb : body Callback.callback)
      : unit
      = createExt m (attrToAbs a) (Callback.handleCallback cb)

  external infoExt
    : t
      -> body Callback.jsCallback
      -> unit
    = "info" [@@bs.send]

    let info
        (m : t)
        (cb : body Callback.callback)
      = infoExt m (Callback.handleCallback cb)

  external deleteExt
    : t
      -> body Callback.jsCallback
      -> unit
    = "delete" [@@bs.send]

    let delete
        (m : t)
        (cb : body Callback.callback)
      = deleteExt m (Callback.handleCallback cb)
end

module Routes = struct
  type t
  type body

  external routesExt
    : mailgunClient
      -> ?id:string
      -> unit
      -> t
    = "routes" [@@bs.send]

    let routes (m : mailgunClient) ?id:(ido : string option) =
      routesExt m ~id:(Belt_Option.mapWithDefault ido "" Helpers.id)

  external listExt
    : t
      -> body Callback.jsCallback
      -> unit
    = "list" [@@bs.send]

    let list
        (m : t)
        (cb : body Callback.callback)
      = listExt m (Callback.handleCallback cb)

  external infoExt
    : t
      -> body Callback.jsCallback
      -> unit
    = "info" [@@bs.send]


    let info
        (m : t)
        (cb : body Callback.callback)
      = infoExt m (Callback.handleCallback cb)

  type actionTypes
    = Forward of string
    | Stop of string
    | Store of string

  type expressionFilters =
    | Recipient of string
    | Header of string
    | CatchAll of string

  let expressionFiltersToString = function
    | Recipient s -> s
    | Header s -> s
    | CatchAll s -> s

  let actionTypesToString = function
    | Forward s -> s
    | Stop s -> s
    | Store s -> s

  let catchAll : expressionFilters =
    CatchAll "catch_all()"

  let matchRecipient (pattern : string) =
    Recipient ("match_recipient('"^ pattern ^"')")

  let matchHeader ~header:(h: string) ~pattern:(p : string) =
    Header ("match_header('"^ h ^"', '"^ p ^"')")

  let stopAction : actionTypes =
    Stop "stop()"

  let forwardAction (url : string) : actionTypes =
    Forward ("forward('"^ url ^"')")

  let storeAction (url : string) : actionTypes =
    Store ("store(notify='"^ url ^"')")

  type routeParams =
    { priority : int
    ; description : string
    ; expression  : expressionFilters
    ; action : actionTypes
    }

  type routeParamsAbs =
    { priority : int
    ; description : string
    ; expression  : string
    ; action : string
    } [@@bs.deriving abstract]

  let paramsToAbs (r : routeParams) : routeParamsAbs =
    routeParamsAbs
      ~priority:r.priority
      ~description:r.description
      ~expression:(expressionFiltersToString r.expression)
      ~action:(actionTypesToString r.action)

  external createExt
    : t
      -> routeParamsAbs
      -> body Callback.jsCallback
      -> unit
    = "create" [@@bs.send]

    let create
        (m : t)
        (r : routeParams)
        (cb : body Callback.callback)
      = createExt m (paramsToAbs r) (Callback.handleCallback cb)

  external updateExt
    : t
      -> routeParamsAbs
      -> body Callback.jsCallback
      -> unit
    = "update" [@@bs.send]

    let update
        (m : t)
        (r : routeParams)
        (cb : body Callback.callback)
      = updateExt m (paramsToAbs r) (Callback.handleCallback cb)

  external deleteExt
    : t
      -> body Callback.jsCallback
      -> unit
    = "delete" [@@bs.send]

    let delete
        (m : t)
        (cb : body Callback.callback)
      = deleteExt m (Callback.handleCallback cb)
end

module Unsubscribes = struct
  type t
  type body

  external unsubscribesExt
    : mailgunClient
      -> ?address: string
      -> unit
      -> t
    = "unsubscribes" [@@bs.send]

    let unsubscribes
        (m : mailgunClient)
        ?address:(a : string option)
      = unsubscribesExt m ~address:(Belt_Option.getWithDefault a "")

  external listExt
    : t
      -> body Callback.jsCallback
      -> unit
    = "list" [@@bs.send]

    let list
        (m : t)
        (cb : body Callback.callback)
      = listExt m (Callback.handleCallback cb)

  external infoExt
    : t
      -> body Callback.jsCallback
      -> unit
    = "info" [@@bs.send]

    let info
        (m : t)
        (cb : body Callback.callback)
      = infoExt m (Callback.handleCallback cb)

  external deleteExt
    : t
      -> body Callback.jsCallback
      -> unit
    = "delete" [@@bs.send]

    let delete
        (m : t)
        (cb : body Callback.callback)
      = deleteExt m (Callback.handleCallback cb)

  type unsubReq =
    { address : string
    ; tag : string option
    ; created_at : Js.Date.t
    }

  type unsubReqAbs =
    { address : string
    ; tag : string
    ; created_at : Js.Date.t
    } [@@bs.deriving abstract]

  let reqToAbs (u : unsubReq) : unsubReqAbs =
    unsubReqAbs
      ~address:u.address
      ~tag:(Belt_Option.getWithDefault u.tag "")
      ~created_at:u.created_at

  external createExt
    : t
      -> unsubReqAbs
      -> body Callback.jsCallback
      -> unit
    = "create" [@@bs.send]

    let create
        (m : t)
        (req : unsubReq)
        (cb : body Callback.callback)
      = createExt m (reqToAbs req) (Callback.handleCallback cb)
end

module Bounces = struct
  type t
  type body

  external bouncesExt
    : mailgunClient
      -> ?address:string
      -> unit
      -> t
    = "bounces" [@@bs.send]

    let bounces
        (m : mailgunClient)
        ?address:(a : string option)
      : unit -> t
      = bouncesExt m ~address:(Belt_Option.getWithDefault a "")

  external listExt
    : t
      -> body Callback.jsCallback
      -> unit
    = "list" [@@bs.send]

    let list
        (m : t)
        (cb : body Callback.callback)
      : unit
      = listExt m (Callback.handleCallback cb)

  external infoExt
    : t
      -> body Callback.jsCallback
      -> unit
    = "info" [@@bs.send]

    let info
        (m : t)
        (cb : body Callback.callback)
      : unit
      = infoExt m (Callback.handleCallback cb)

  external deleteExt
    : t
      -> body Callback.jsCallback
      -> unit
    = "delete" [@@bs.send]

    let delete
        (m : t)
        (cb : body Callback.callback)
      = deleteExt m (Callback.handleCallback cb)

  type bounceReqAbs =
    { address : string
    ; code : int
    ; error : string
    ; created_at : Js.Date.t
    } [@@bs.deriving abstract]

  type bounceReq =
    { address : string
    ; code : int
    ; error : string
    ; created_at : Js.Date.t
    }

  let reqToAbs (b : bounceReq) =
    bounceReqAbs
      ~address:b.address
      ~code:b.code
      ~error:b.error
      ~created_at:b.created_at

  external createExt
    : t
      -> bounceReqAbs
      -> body Callback.jsCallback
      -> unit
    = "create" [@@bs.send]

    let create
        (m : t)
        (req : bounceReq)
        (cb : body Callback.callback)
        : unit
      = createExt m (reqToAbs req) (Callback.handleCallback cb)
end
