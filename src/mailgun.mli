type mailgunReq =
  { apiKey : string
  ; domain : string
  } [@@bs.deriving abstract]

type mailgunClient

val mailgun
  : mailgunReq
  -> mailgunClient

module Callback : sig
  type nullableError = Js.Exn.t Js.Nullable.t
  type 'a jsCallback = Js.Exn.t Js.Nullable.t -> 'a -> unit
  type 'a callback = ('a, nullableError) Belt_Result.t -> unit
end

type emailData =
  { from : string
  ; to_ : string [@bs.as "to"]
  ; subject : string
  ; text : string
  } [@@bs.deriving abstract]

module Message : sig
  type t
  type body = Js.Json.t

  val messages : mailgunClient -> t

  val send
    : t
    -> emailData
    -> body Callback.callback
    -> unit

  val sendMime
    : t
    -> emailData
    -> body Callback.callback
    -> unit
end

module MailingList : sig
  type t
  type body
  type createReq =
    { address : string
    ; name : string
    ; description : string
    ; access_level : string
    } [@@bs.deriving abstract]

  val lists
    : mailgunClient
    -> ?aliasAddress:string
    -> unit
    -> t

  val info
    : t
    -> body Callback.callback
    -> unit

  val create
    : t
    -> createReq
    -> body Callback.callback
    -> unit
end

module MailingListMembers : sig
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

  val members
    : MailingList.t
    -> mailingListMembers

  val createMember
    : mailingListMembers
    -> memberReq
    -> body Callback.callback
    -> unit

  val memberList
    : mailingListMembers
    -> members Callback.callback
    -> unit
end

module Domain : sig
  type t
  type body

  type spam_action
    = Disabled
    | Block
    | Tag

  type dkim_key_size
    = High
    | Low

  type createReq =
    { name : string
    ; smtp_password : string
    ; spam_action : spam_action
    ; wildcard : bool
    ; force_dkim_authority : bool
    ; dkim_key_size : dkim_key_size
    ; ips : string list
    }

  val domains
    : mailgunClient
    -> ?domain:string
    -> unit
    -> t

  val list
    : t
    -> body Callback.callback
    -> unit

  val info
    : mailgunClient
    -> domain:string
    -> body Callback.callback
    -> unit

  val create
    : t
    -> createReq
    -> body Callback.callback
    -> unit
end

module Credentials : sig
  type t
  type body
  type createReq =
    { login : string
    ; password : string
    }

  val credentials
    : Domain.t
    -> ?login:string
    -> unit
    -> t

  val list
    : t
    -> body Callback.callback
    -> unit

  val create
    : t
    -> createReq
    -> body Callback.callback
    -> unit

  val delete
    : t
    -> body Callback.callback
    -> unit
end

module Tracking : sig
  type t
  type body
  type openTracking
  type clickTracking
  type unsubscribeTracking
  type subscriptionAttr =
    { active : bool
    ; html_footer : string option
    ; text_footer : string option
    }

  type isActive
    = Yes
    | No
    | HtmlOnly

  val tracking : Domain.t -> t
  val info : t -> body Callback.callback -> unit
  val openTracking : t -> openTracking
  val updateOpenTracking
    : openTracking
    -> isActive
    -> body Callback.callback
    -> unit
  val clickTracking
    : t -> clickTracking
  val updateClickTracking
    : clickTracking
    -> isActive
    -> body Callback.callback
    -> unit
  val unsubscribeTracking : t -> unsubscribeTracking
  val updateSubscription
    : unsubscribeTracking
    -> subscriptionAttr
    -> body Callback.callback
    -> unit
end

module Complaints : sig
  type t
  type body
  type attr =
    { address : string }

  val complaints : mailgunClient -> ?address:string -> unit -> t
  val list : t -> body Callback.callback -> unit
  val create : t -> attr -> body Callback.callback -> unit
  val info : t -> body Callback.callback -> unit
  val delete : t -> body Callback.callback -> unit
end

module Routes : sig
  type t
  type body
  type actionTypes
    = Forward of string
    | Stop of string
    | Store of string

  type expressionFilters =
    | Recipient of string
    | Header of string
    | CatchAll of string

  type routeParams =
    { priority : int
    ; description : string
    ; expression  : expressionFilters
    ; action : actionTypes
    }
  val routes : mailgunClient -> ?id:string -> unit -> t
  val list : t -> body Callback.callback -> unit
  val forwardAction : string -> actionTypes
  val stopAction : actionTypes
  val storeAction : string -> actionTypes
  val matchRecipient : string -> expressionFilters
  val matchHeader : header:string -> pattern:string -> expressionFilters
  val catchAll : expressionFilters
  val info : t -> body Callback.callback -> unit
  val create : t -> routeParams -> body Callback.callback -> unit
  val update : t -> routeParams -> body Callback.callback -> unit
  val delete : t -> body Callback.callback -> unit
end

module Unsubscribes : sig
  type t
  type body
  type unsubReq =
    { address : string
    ; tag : string option
    ; created_at : Js.Date.t
    }

  val unsubscribes : mailgunClient -> ?address:string -> unit -> t
  val list : t -> body Callback.callback -> unit
  val info : t -> body Callback.callback -> unit
  val delete : t -> body Callback.callback -> unit
  val create : t -> unsubReq -> body Callback.callback -> unit
end

module Bounces : sig
  type t
  type body
  type bounceReq =
    { address : string
    ; code : int
    ; error : string
    ; created_at : Js.Date.t
    }

  val bounces : mailgunClient -> ?address:string -> unit -> t
  val list : t -> body Callback.callback -> unit
  val info : t -> body Callback.callback -> unit
  val delete : t -> body Callback.callback -> unit
  val create : t -> bounceReq -> body Callback.callback -> unit
end
