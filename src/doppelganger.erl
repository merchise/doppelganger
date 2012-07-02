-module(doppelganger).
-vsn("1.0.0").
-behaviour(gen_server).

-export([replicate/1, replicate/3]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3, start_link/0, stop/0]).
-compile([{parse_transform,lager_transform}]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% EXPORTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
replicate(RiakObject) ->  
  {Host,Port} = get_server(),
  {ok, Pid} = riakc_pb_socket:start(Host, Port),
  try
    IsActive = get_env(active,false),
    replicate({active,IsActive}, Pid,RiakObject)
  catch
    Class:Exception ->
      lager:error("Unable to save because of ~p: ~p", [Class,Exception])
  end,
  riakc_pb_socket:stop(Pid).

replicate({active,true},Pid,RiakObject) ->  
  %lager:debug("Saving to riakc pid ~p: ~p", [Pid,RiakObject]),
  RCObject = get_riakc_obj(RiakObject),
  riakc_pb_socket:put(Pid,RCObject);
  %lager:debug("Save complete");

replicate({active,false},_,_) -> ok.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PRIVATE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_riakc_obj(RObject) ->
  B = riak_object:bucket(RObject),
  K = riak_object:key(RObject),
  V = riak_object:get_value(RObject),
  riakc_obj:new(B,K,V).

get_server() ->
  Host = get_env(riak_host, {error, no_host_defined}),
  Port = get_env(riak_port, 8091),
  {Host,Port}.

get_env(Key,Default) ->
  case application:get_env(doppelganger,Key) of
    undefined ->
      lager:info("Using default ~p = ~p for riakc", [Key,Default]),
      Default;
    {ok,V} -> V
  end.

node_id() -> {local,?MODULE}.
start_link() ->
  gen_server:start_link(node_id(), ?MODULE, [], []).

stop() ->
  gen_server:cast(?MODULE, stop).

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% --------------------------------------------------------------------
init(_Args) ->
  process_flag(trap_exit,true),
  {ok, {}}.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% --------------------------------------------------------------------
%% TODO: Add a catch to see if 
handle_call(_Request, _From, State) ->
  {reply, ok, State}.


%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% --------------------------------------------------------------------
handle_cast(stop, State) ->
  {stop, normal, State};

handle_cast(_Msg, State) ->
  {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% --------------------------------------------------------------------
handle_info(_Info, State) ->
  {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
  ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
  {ok, State}.
