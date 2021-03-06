% Licensed under the Apache License, Version 2.0 (the "License"); you may not
% use this file except in compliance with the License. You may obtain a copy of
% the License at
%
%   http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
% WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
% License for the specific language governing permissions and limitations under
% the License.


% The value a key can have. For the vtree that is either a number or
% (UTF-8) string. `nil` is used as a wildcard in queries, to match open or
% full ranges.
-type keyval() :: number() | string() | nil.

% The multidimensional bounding box
-type mbb() :: [{Min :: keyval(), Max :: keyval()}].

-type geom_type() :: 'Point' | 'LineString' | 'Polygon' | 'MultiPoint' |
                     'MultiLineString' | 'MultiPolygon' | 'GeometryCollection'.
-type geom_coords() :: [number()] | [geom_coords()].
-type geom() :: {Type :: geom_type(), Coordinates :: geom_coords()}.

% No idea what the json type will be yet
-type json() :: any().

-type kp_value() :: {PointerNode :: non_neg_integer(),
                     TreeSize :: non_neg_integer(), Reduce :: any()}.
-type kv_value() :: {DocId :: binary(), Geometry :: geom(), Body :: json()}.

-type candidate() :: {[split_node()], [split_node()]}.

% The less function compares two values and returns true if the former is
% less than the latter
-type lessfun() :: fun((keyval(), keyval()) -> boolean()).


-define(KP_NODE, 0).
-define(KV_NODE, 1).


-record(kv_node, {
          key = [] :: mbb(),
          docid = nil :: binary() | nil ,
          geometry = nil :: geom() | nil | pos_integer(),
          body = nil :: json() | nil | pos_integer(),
          % The body and the geometry are stored on disk early. Store their
          % size here. A value of -1 means that the `geometry` and the `body`
          % property are pointers, but the size is not known. A value of 0
          % means that the size wasn't set yet and the `geometry` and `body`
          % contain the actual values
          size = 0 :: integer(),
          partition = 0 :: non_neg_integer()
}).

-record(kp_node, {
          key = [] :: mbb(),
          childpointer = [] :: non_neg_integer(),
          treesize = 0 :: non_neg_integer(),
          reduce = nil :: any(),
          mbb_orig = [] :: mbb()
}).

-record(vtree, {
          fd = nil :: file:io_device() | nil,
          % The root node of the tree
          %root = nil ::kp_value() | kv_value()
          root = nil :: #kp_node{} | nil,
          less = fun(A, B) -> A < B end,
          reduce = nil :: any(),
          % `kp_chunk_threshold` and `kv_chunk_threshold` are normally set by
          % vtree_state (which is part of the Couchbase/Apache CouchDB API
          % implementation)
          kp_chunk_threshold = nil :: number() | nil,
          kv_chunk_threshold = nil :: number() | nil,
          % The value of the minimum fill rate of a node should always be
          % below 0.5.
          min_fill_rate = 0.4 :: number()
}).

%% The node format for the splits. It contains the MBB and in case of a:
%%  1. KV node: the pointer to the node in the file
%%  2. KP node: a list of pointers to its children
%%  3. abused: any value
-type split_node() :: {Mbb :: mbb(), KvOrKpv :: #kv_node{} | #kp_node{} | any()}.
