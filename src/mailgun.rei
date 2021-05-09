[@bs.deriving abstract]
type mailgunReq = {
  apiKey: string,
  domain: string
};

type mailgunClient;

let mailgun: mailgunReq => mailgunClient;

module Callback: {
  type nullableError = Js.Nullable.t(Js.Exn.t);
  type jsCallback('a) = (Js.Nullable.t(Js.Exn.t), 'a) => unit;
  type callback('a) = Belt_Result.t('a, nullableError) => unit;
};

[@bs.deriving abstract]
type emailData = {
  from: string,
  to_: string,
  subject: string,
  text: string
};

module Message: {
  type t;
  type body = Js.Json.t;
  let messages: mailgunClient => t;
  let send: (t, emailData, Callback.callback(body)) => unit;
  let sendMime: (t, emailData, Callback.callback(body)) => unit;
};

module MailingList: {
  type t;
  type body;
  [@bs.deriving abstract]
  type createReq = {
    address: string,
    name: string,
    description: string,
    access_level: string
  };
  let lists: (mailgunClient, ~aliasAddress: string=?, unit) => t;
  let info: (t, Callback.callback(body)) => unit;
  let create: (t, createReq, Callback.callback(body)) => unit;
};

module MailingListMembers: {
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
  let members: MailingList.t => mailingListMembers;
  let createMember: (mailingListMembers, memberReq, Callback.callback(body)) => unit;
  let memberList: (mailingListMembers, Callback.callback(members)) => unit;
};

module Domain: {
  type t;
  type body;
  type spam_action =
    | Disabled
    | Block
    | Tag;
  type dkim_key_size =
    | High
    | Low;
  type createReq = {
    name: string,
    smtp_password: string,
    spam_action,
    wildcard: bool,
    force_dkim_authority: bool,
    dkim_key_size,
    ips: list(string)
  };
  let domains: (mailgunClient, ~domain: string=?, unit) => t;
  let list: (t, Callback.callback(body)) => unit;
  let info: (mailgunClient, ~domain: string, Callback.callback(body)) => unit;
  let create: (t, createReq, Callback.callback(body)) => unit;
};

module Credentials: {
  type t;
  type body;
  type createReq = {
    login: string,
    password: string
  };
  let credentials: (Domain.t, ~login: string=?, unit) => t;
  let list: (t, Callback.callback(body)) => unit;
  let create: (t, createReq, Callback.callback(body)) => unit;
  let delete: (t, Callback.callback(body)) => unit;
};

module Tracking: {
  type t;
  type body;
  type openTracking;
  type clickTracking;
  type unsubscribeTracking;
  type subscriptionAttr = {
    active: bool,
    html_footer: option(string),
    text_footer: option(string)
  };
  type isActive =
    | Yes
    | No
    | HtmlOnly;
  let tracking: Domain.t => t;
  let info: (t, Callback.callback(body)) => unit;
  let openTracking: t => openTracking;
  let updateOpenTracking: (openTracking, isActive, Callback.callback(body)) => unit;
  let clickTracking: t => clickTracking;
  let updateClickTracking: (clickTracking, isActive, Callback.callback(body)) => unit;
  let unsubscribeTracking: t => unsubscribeTracking;
  let updateSubscription: (unsubscribeTracking, subscriptionAttr, Callback.callback(body)) => unit;
};

module Complaints: {
  type t;
  type body;
  type attr = {address: string};
  let complaints: (mailgunClient, ~address: string=?, unit) => t;
  let list: (t, Callback.callback(body)) => unit;
  let create: (t, attr, Callback.callback(body)) => unit;
  let info: (t, Callback.callback(body)) => unit;
  let delete: (t, Callback.callback(body)) => unit;
};

module Routes: {
  type t;
  type body;
  type actionTypes =
    | Forward(string)
    | Stop(string)
    | Store(string);
  type expressionFilters =
    | Recipient(string)
    | Header(string)
    | CatchAll(string);
  type routeParams = {
    priority: int,
    description: string,
    expression: expressionFilters,
    action: actionTypes
  };
  let routes: (mailgunClient, ~id: string=?, unit) => t;
  let list: (t, Callback.callback(body)) => unit;
  let forwardAction: string => actionTypes;
  let stopAction: actionTypes;
  let storeAction: string => actionTypes;
  let matchRecipient: string => expressionFilters;
  let matchHeader: (~header: string, ~pattern: string) => expressionFilters;
  let catchAll: expressionFilters;
  let info: (t, Callback.callback(body)) => unit;
  let create: (t, routeParams, Callback.callback(body)) => unit;
  let update: (t, routeParams, Callback.callback(body)) => unit;
  let delete: (t, Callback.callback(body)) => unit;
};

module Unsubscribes: {
  type t;
  type body;
  type unsubReq = {
    address: string,
    tag: option(string),
    created_at: Js.Date.t
  };
  let unsubscribes: (mailgunClient, ~address: string=?, unit) => t;
  let list: (t, Callback.callback(body)) => unit;
  let info: (t, Callback.callback(body)) => unit;
  let delete: (t, Callback.callback(body)) => unit;
  let create: (t, unsubReq, Callback.callback(body)) => unit;
};

module Bounces: {
  type t;
  type body;
  type bounceReq = {
    address: string,
    code: int,
    error: string,
    created_at: Js.Date.t
  };
  let bounces: (mailgunClient, ~address: string=?, unit) => t;
  let list: (t, Callback.callback(body)) => unit;
  let info: (t, Callback.callback(body)) => unit;
  let delete: (t, Callback.callback(body)) => unit;
  let create: (t, bounceReq, Callback.callback(body)) => unit;
};
