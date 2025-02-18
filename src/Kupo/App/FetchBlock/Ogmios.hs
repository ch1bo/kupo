--  This Source Code Form is subject to the terms of the Mozilla Public
--  License, v. 2.0. If a copy of the MPL was not distributed with this
--  file, You can obtain one at http://mozilla.org/MPL/2.0/.

module Kupo.App.FetchBlock.Ogmios
    ( withFetchBlockClient
    ) where

import Kupo.Prelude

import Kupo.Data.FetchBlock
    ( FetchBlockClient
    )
import Kupo.Data.Ogmios
    ( PartialBlock
    , RequestNextResponse (..)
    , decodeFindIntersectResponse
    , decodeRequestNextResponse
    , encodeFindIntersect
    , encodeRequestNext
    )

import qualified Network.WebSockets as WS
import qualified Network.WebSockets.Json as WS

withFetchBlockClient
    :: String
    -> Int
    -> (FetchBlockClient IO PartialBlock -> IO ())
    -> IO ()
withFetchBlockClient host port action =
    action $ \point reply -> WS.runClient host port "/" $ \ws -> do
        WS.sendJson ws (encodeFindIntersect [point])
        WS.receiveJson ws (decodeFindIntersectResponse identity) >>= \case
            Left _notFound -> reply Nothing
            Right{} -> do
                replicateM_ 2 (WS.sendJson ws encodeRequestNext)
                -- NOTE: The first reply is always a 'Roll-Backward' to the requested point. Ignore.
                void (WS.receiveJson ws decodeRequestNextResponse)
                WS.receiveJson ws decodeRequestNextResponse >>= \case
                    RollBackward _tip _point -> do
                        reply Nothing
                    RollForward _tip block -> do
                        reply (Just block)
