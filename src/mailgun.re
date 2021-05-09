type mailgunClient;

[@bs.deriving abstract]
type mailgunReq = {
  apiKey: string,
  domain: string
};

[@bs.module] external mailgunExt : mailgunReq => mailgunClient = "mailgun-js";

let mailgun = (req: mailgunReq) : mailgunClient => mailgunExt(req);

[@bs.deriving abstract]
type emailData = {
  from: string,
  to_: string,
  subject: string,
  text: string
};

module Callback = {
  type nullableError = Js.Nullable.t(Js.Exn.t);
  type jsCallback('a) = (Js.Nullable.t(Js.Exn.t), 'a) => unit;
  type callback('a) = Belt_Result.t('a, nullableError) => unit;
  let handleCallbackImpl =
      (
        l: Js.Nullable.t(Js.Exn.t) => Belt_Result.t('a, nullableError),
        r: 'a => Belt_Result.t('a, nullableError),
        f: callback('a),
        err: nullableError,
        value: 'a
      ) =>
    Js.Nullable.isNullable(err) ? f @@ r(value) : f @@ l(err);
  let handleCallback = (cb: callback('a)) =>
    handleCallbackImpl((l) => Belt_Result.Error(l), (r) => Belt_Result.Ok(r), cb);
};

module Message = {
  type t;
  type body = Js.Json.t;
  [@bs.send] external messagesExt : mailgunClient => t = "messages";
  let messages = (mg: mailgunClient) : t => messagesExt(mg);
  [@bs.send] external sendExt : (t, emailData, Callback.jsCallback(body)) => unit = "send";
  let send = (m: t, e: emailData, cb: Callback.callback(body)) : unit =>
    sendExt(m, e, Callback.handleCallback(cb));
  [@bs.send] external sendMimeExt : (t, emailData, Callback.jsCallback(body)) => unit = "sendMime";
  let sendMime = (m: t, e: emailData, cb: Callback.callback(body)) =>
    sendMimeExt(m, e, Callback.handleCallback(cb));
};

module MailingList = {
  type t;
  type body;
  [@bs.deriving abstract]
  type createReq = {
    address: string,
    name: string,
    description: string,
    access_level: string
  };
  [@bs.send] external listsExt : (mailgunClient, ~aliasAddress: string=?) => t = "lists";
  let lists = (m: mailgunClient, ~aliasAddress as e: option(string)=?, ()) =>
    listsExt(m, ~aliasAddress=Belt_Option.mapWithDefault(e, "", Helpers.id));
  [@bs.send] external infoExt : (t, Callback.jsCallback(body)) => unit = "info";
  let info = (l: t, cb: Callback.callback(body)) : unit => infoExt(l, Callback.handleCallback(cb));
  [@bs.send] external createExt : (t, createReq, Callback.jsCallback(body)) => unit = "create";
  let create = (l: t, c: createReq, cb: Callback.callback(body)) =>
    createExt(l, c, Callback.handleCallback(cb));
};

module MailingListMembers = {
  type mailingListMembers;
  type members;
  type body;
  [@bs.deriving abstract]
  type memberReq = {
    memberAddress: string,
    name: string,
    vars: Js.Json.t,
    subscribed: bool,
    upsert: bool
  };
  [@bs.send] external membersExt : (MailingList.t, unit) => mailingListMembers = "members";
  let members = (m: MailingList.t) => membersExt(m, ());
  [@bs.send]
  external createMembersExt : (mailingListMembers, memberReq, Callback.jsCallback(body)) => unit =
    "create";
  let createMember = (c: mailingListMembers, m: memberReq, cb: Callback.callback(body)) : unit =>
    createMembersExt(c, m, Callback.handleCallback(cb));
  [@bs.send]
  external memberListExt : (mailingListMembers, Callback.jsCallback(members)) => unit = "list";
  let memberList = (ml: mailingListMembers, cb: Callback.callback(members)) : unit =>
    memberListExt(ml, Callback.handleCallback(cb));
};

module Domain = {
  type t;
  type body;
  type spam_action =
    | Disabled
    | Block
    | Tag;
  let spamActionToString: spam_action => string =
    fun
    | Disabled => "disabled"
    | Block => "block"
    | Tag => "tag";
  type dkim_key_size =
    | High
    | Low;
  let dkimKeySizeToInt: dkim_key_size => int =
    fun
    | Low => 1024
    | High => 2048;
  type createReq = {
    name: string,
    smtp_password: string,
    spam_action,
    wildcard: bool,
    force_dkim_authority: bool,
    dkim_key_size,
    ips: list(string)
  };
  [@bs.deriving abstract]
  type createReqFfi = {
    name: string,
    smtp_password: string,
    spam_action: string,
    wildcard: bool,
    force_dkim_authority: bool,
    dkim_key_size: int,
    ips: list(string)
  };
  [@bs.send] external domainsExt : (mailgunClient, ~domain: string=?, unit) => t = "domains";
  let domains = (mg: mailgunClient, ~domain as d: option(string)=?, ()) : t =>
    domainsExt(mg, ~domain=Belt_Option.mapWithDefault(d, "", Helpers.id), ());
  [@bs.send] external listExt : (t, Callback.jsCallback(body)) => unit = "list";
  let list = (m: t, cb: Callback.callback(body)) : unit => listExt(m, Callback.handleCallback(cb));
  [@bs.send] external infoExt : (t, Callback.jsCallback(body)) => unit = "info";
  let info = (mg: mailgunClient, ~domain as d: string, cb: Callback.callback(body)) : unit =>
    infoExt(domains(mg, ~domain=d, ()), Callback.handleCallback(cb));
  [@bs.send] external createExt : (t, createReqFfi, Callback.jsCallback(body)) => unit = "create";
  let create = (m: t, c: createReq, cb: Callback.callback(body)) : unit =>
    createExt(
      m,
      createReqFfi(
        ~name=c.name,
        ~spam_action=spamActionToString(c.spam_action),
        ~smtp_password=c.smtp_password,
        ~wildcard=c.wildcard,
        ~force_dkim_authority=c.force_dkim_authority,
        ~dkim_key_size=dkimKeySizeToInt(c.dkim_key_size),
        ~ips=c.ips
      ),
      Callback.handleCallback(cb)
    );
};

module Credentials = {
  type t;
  type body;
  type createReq = {
    login: string,
    password: string
  };
  [@bs.deriving abstract]
  type createReqFfi = {
    login: string,
    password: string
  };
  [@bs.send] external credentialsExt : (Domain.t, ~login: string=?, unit) => t = "credentials";
  let credentials = (d: Domain.t, ~login as l: option(string)=?, ()) : t =>
    credentialsExt(d, ~login=Belt_Option.mapWithDefault(l, "", Helpers.id), ());
  [@bs.send] external listExt : (t, Callback.jsCallback(body)) => unit = "list";
  let list = (m: t, cb: Callback.callback(body)) : unit => listExt(m, Callback.handleCallback(cb));
  [@bs.send] external createExt : (t, createReqFfi, Callback.jsCallback(body)) => unit = "create";
  let create = (m: t, c: createReq, cb: Callback.callback(body)) : unit =>
    createExt(m, createReqFfi(~login=c.login, ~password=c.password), Callback.handleCallback(cb));
  [@bs.send] external deleteExt : (t, Callback.jsCallback(body)) => unit = "delete";
  let delete = (m: t, cb: Callback.callback(body)) : unit =>
    deleteExt(m, Callback.handleCallback(cb));
};

module Tracking = {
  type t;
  type body;
  type openTracking;
  type clickTracking;
  type unsubscribeTracking;
  [@bs.send] external trackingExt : (Domain.t, unit) => t = "tracking";
  let tracking = (d: Domain.t) => trackingExt(d, ());
  [@bs.send] external infoExt : (t, Callback.jsCallback(body)) => unit = "info";
  let info = (m: t, cb: Callback.callback(body)) => infoExt(m, Callback.handleCallback(cb));
  [@bs.send] external openExt : (t, unit) => openTracking = "open";
  let openTracking = (m: t) => openExt(m, ());
  type isActive =
    | Yes
    | No
    | HtmlOnly;
  [@bs.deriving abstract]
  type activeAttribute = {active: string};
  let isActiveToAbstract: isActive => activeAttribute = {
    let createRec = (s) => activeAttribute(~active=s);
    fun
    | Yes => createRec("yes")
    | No => createRec("no")
    | HtmlOnly => createRec("htmlonly");
  };
  [@bs.send]
  external updateOpenTrackingExt :
    (openTracking, activeAttribute, Callback.jsCallback(body)) => unit =
    "update";
  let updateOpenTracking = (o: openTracking, a: isActive, cb: Callback.callback(body)) =>
    updateOpenTrackingExt(o, isActiveToAbstract(a), Callback.handleCallback(cb));
  [@bs.send] external clickExt : (t, unit) => clickTracking = "click";
  let clickTracking = (m: t) : clickTracking => clickExt(m, ());
  [@bs.send]
  external updateClickTrackingExt :
    (clickTracking, activeAttribute, Callback.jsCallback(body)) => unit =
    "update";
  let updateClickTracking = (c: clickTracking, a: isActive, cb: Callback.callback(body)) =>
    updateClickTrackingExt(c, isActiveToAbstract(a), Callback.handleCallback(cb));
  [@bs.send] external unsubscribeExt : (t, unit) => unsubscribeTracking = "unsubscribe";
  let unsubscribeTracking = (m: t) : unsubscribeTracking => unsubscribeExt(m, ());
  /* subscriptionAttr will be used by the user */
  type subscriptionAttr = {
    active: bool,
    html_footer: option(string),
    text_footer: option(string)
  };
  /* subscriptionAttrAbs is hidden from the consumer of this lib and is
     only used for interop with json.*/
  [@bs.deriving abstract]
  type subscriptionAttrAbs = {
    active: bool,
    html_footer: string,
    text_footer: string
  };
  let subAttrToAbs = (s: subscriptionAttr) : subscriptionAttrAbs =>
    Belt_Option.(
      subscriptionAttrAbs(
        ~active=s.active,
        ~text_footer=mapWithDefault(s.text_footer, "", Helpers.id),
        ~html_footer=mapWithDefault(s.html_footer, "", Helpers.id)
      )
    );
  [@bs.send]
  external updateSubscriptionExt :
    (unsubscribeTracking, subscriptionAttrAbs, Callback.jsCallback(body)) => unit =
    "update";
  let updateSubscription =
      (c: unsubscribeTracking, s: subscriptionAttr, cb: Callback.callback(body)) =>
    updateSubscriptionExt(c, subAttrToAbs(s), Callback.handleCallback(cb));
};

module Complaints = {
  type t;
  type body;
  type attr = {address: string};
  [@bs.deriving abstract]
  type attrAbs = {address: string};
  let attrToAbs = (a: attr) : attrAbs => attrAbs(~address=a.address);
  [@bs.send] external complaintsExt : (mailgunClient, ~address: string=?) => t = "complaints";
  let complaints = (m: mailgunClient, ~address as a: option(string)=?, ()) : t =>
    complaintsExt(m, ~address=Belt_Option.mapWithDefault(a, "", Helpers.id));
  [@bs.send] external listExt : (t, Callback.jsCallback(body)) => unit = "list";
  let list = (m: t, cb: Callback.callback(body)) => listExt(m, Callback.handleCallback(cb));
  [@bs.send] external createExt : (t, attrAbs, Callback.jsCallback(body)) => unit = "create";
  let create = (m: t, a: attr, cb: Callback.callback(body)) : unit =>
    createExt(m, attrToAbs(a), Callback.handleCallback(cb));
  [@bs.send] external infoExt : (t, Callback.jsCallback(body)) => unit = "info";
  let info = (m: t, cb: Callback.callback(body)) => infoExt(m, Callback.handleCallback(cb));
  [@bs.send] external deleteExt : (t, Callback.jsCallback(body)) => unit = "delete";
  let delete = (m: t, cb: Callback.callback(body)) => deleteExt(m, Callback.handleCallback(cb));
};

module Routes = {
  type t;
  type body;
  [@bs.send] external routesExt : (mailgunClient, ~id: string=?, unit) => t = "routes";
  let routes = (m: mailgunClient, ~id as ido: option(string)=?) =>
    routesExt(m, ~id=Belt_Option.mapWithDefault(ido, "", Helpers.id));
  [@bs.send] external listExt : (t, Callback.jsCallback(body)) => unit = "list";
  let list = (m: t, cb: Callback.callback(body)) => listExt(m, Callback.handleCallback(cb));
  [@bs.send] external infoExt : (t, Callback.jsCallback(body)) => unit = "info";
  let info = (m: t, cb: Callback.callback(body)) => infoExt(m, Callback.handleCallback(cb));
  type actionTypes =
    | Forward(string)
    | Stop(string)
    | Store(string);
  type expressionFilters =
    | Recipient(string)
    | Header(string)
    | CatchAll(string);
  let expressionFiltersToString =
    fun
    | Recipient(s) => s
    | Header(s) => s
    | CatchAll(s) => s;
  let actionTypesToString =
    fun
    | Forward(s) => s
    | Stop(s) => s
    | Store(s) => s;
  let catchAll: expressionFilters = CatchAll("catch_all()");
  let matchRecipient = (pattern: string) => Recipient("match_recipient('" ++ pattern ++ "')");
  let matchHeader = (~header as h: string, ~pattern as p: string) =>
    Header("match_header('" ++ h ++ "', '" ++ p ++ "')");
  let stopAction: actionTypes = Stop("stop()");
  let forwardAction = (url: string) : actionTypes => Forward("forward('" ++ url ++ "')");
  let storeAction = (url: string) : actionTypes => Store("store(notify='" ++ url ++ "')");
  type routeParams = {
    priority: int,
    description: string,
    expression: expressionFilters,
    action: actionTypes
  };
  [@bs.deriving abstract]
  type routeParamsAbs = {
    priority: int,
    description: string,
    expression: string,
    action: string
  };
  let paramsToAbs = (r: routeParams) : routeParamsAbs =>
    routeParamsAbs(
      ~priority=r.priority,
      ~description=r.description,
      ~expression=expressionFiltersToString(r.expression),
      ~action=actionTypesToString(r.action)
    );
  [@bs.send]
  external createExt : (t, routeParamsAbs, Callback.jsCallback(body)) => unit = "create";
  let create = (m: t, r: routeParams, cb: Callback.callback(body)) =>
    createExt(m, paramsToAbs(r), Callback.handleCallback(cb));
  [@bs.send]
  external updateExt : (t, routeParamsAbs, Callback.jsCallback(body)) => unit = "update";
  let update = (m: t, r: routeParams, cb: Callback.callback(body)) =>
    updateExt(m, paramsToAbs(r), Callback.handleCallback(cb));
  [@bs.send] external deleteExt : (t, Callback.jsCallback(body)) => unit = "delete";
  let delete = (m: t, cb: Callback.callback(body)) => deleteExt(m, Callback.handleCallback(cb));
};

module Unsubscribes = {
  type t;
  type body;
  [@bs.send]
  external unsubscribesExt : (mailgunClient, ~address: string=?, unit) => t = "unsubscribes";
  let unsubscribes = (m: mailgunClient, ~address as a: option(string)=?) =>
    unsubscribesExt(m, ~address=Belt_Option.getWithDefault(a, ""));
  [@bs.send] external listExt : (t, Callback.jsCallback(body)) => unit = "list";
  let list = (m: t, cb: Callback.callback(body)) => listExt(m, Callback.handleCallback(cb));
  [@bs.send] external infoExt : (t, Callback.jsCallback(body)) => unit = "info";
  let info = (m: t, cb: Callback.callback(body)) => infoExt(m, Callback.handleCallback(cb));
  [@bs.send] external deleteExt : (t, Callback.jsCallback(body)) => unit = "delete";
  let delete = (m: t, cb: Callback.callback(body)) => deleteExt(m, Callback.handleCallback(cb));
  type unsubReq = {
    address: string,
    tag: option(string),
    created_at: Js.Date.t
  };
  [@bs.deriving abstract]
  type unsubReqAbs = {
    address: string,
    tag: string,
    created_at: Js.Date.t
  };
  let reqToAbs = (u: unsubReq) : unsubReqAbs =>
    unsubReqAbs(
      ~address=u.address,
      ~tag=Belt_Option.getWithDefault(u.tag, ""),
      ~created_at=u.created_at
    );
  [@bs.send] external createExt : (t, unsubReqAbs, Callback.jsCallback(body)) => unit = "create";
  let create = (m: t, req: unsubReq, cb: Callback.callback(body)) =>
    createExt(m, reqToAbs(req), Callback.handleCallback(cb));
};

module Bounces = {
  type t;
  type body;
  [@bs.send] external bouncesExt : (mailgunClient, ~address: string=?, unit) => t = "bounces";
  let bounces = (m: mailgunClient, ~address as a: option(string)=?) : (unit => t) =>
    bouncesExt(m, ~address=Belt_Option.getWithDefault(a, ""));
  [@bs.send] external listExt : (t, Callback.jsCallback(body)) => unit = "list";
  let list = (m: t, cb: Callback.callback(body)) : unit => listExt(m, Callback.handleCallback(cb));
  [@bs.send] external infoExt : (t, Callback.jsCallback(body)) => unit = "info";
  let info = (m: t, cb: Callback.callback(body)) : unit => infoExt(m, Callback.handleCallback(cb));
  [@bs.send] external deleteExt : (t, Callback.jsCallback(body)) => unit = "delete";
  let delete = (m: t, cb: Callback.callback(body)) => deleteExt(m, Callback.handleCallback(cb));
  [@bs.deriving abstract]
  type bounceReqAbs = {
    address: string,
    code: int,
    error: string,
    created_at: Js.Date.t
  };
  type bounceReq = {
    address: string,
    code: int,
    error: string,
    created_at: Js.Date.t
  };
  let reqToAbs = (b: bounceReq) =>
    bounceReqAbs(~address=b.address, ~code=b.code, ~error=b.error, ~created_at=b.created_at);
  [@bs.send] external createExt : (t, bounceReqAbs, Callback.jsCallback(body)) => unit = "create";
  let create = (m: t, req: bounceReq, cb: Callback.callback(body)) : unit =>
    createExt(m, reqToAbs(req), Callback.handleCallback(cb));
};
