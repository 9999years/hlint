{-# LANGUAGE PatternGuards, ScopedTypeVariables, RecordWildCards, ViewPatterns #-}

module Test.Util(
	withTests, tested, passed, failed, progress
    ) where

import Data.IORef
import System.IO.Unsafe
import Control.Exception
import Control.Monad
import System.IO


data Result = Result {failures :: Int, total :: Int} deriving Show

{-# NOINLINE ref #-}
ref :: IORef [Result]
ref = unsafePerformIO $ newIORef []

-- | Returns the number of failing tests.
--   Warning: Not multithread safe, but is reenterant
withTests :: IO () -> IO Int
withTests act = bracket (hGetBuffering stdout) (hSetBuffering stdout) $ const $ do
    hSetBuffering stdout NoBuffering
    atomicModifyIORef ref $ \r -> (Result 0 0 : r, ())
    act
    Result{..} <- atomicModifyIORef ref $ \(r:rs) -> (rs, r)
    putStrLn ""
    putStrLn $ if failures == 0
        then "Tests passed (" ++ show total ++ ")"
        else "Tests failed (" ++ show failures ++ " of " ++ show total ++ ")"
    return failures

progress :: String -> IO ()
progress x = putStr $ take mx (x ++ "..." ++ replicate mx ' ') ++ replicate mx '\b'
    where mx = 69

passed :: IO ()
passed = do
	atomicModifyIORef ref $ \(r:rs) -> (r{total=total r+1}:rs, ())

failed :: [String] -> IO ()
failed xs = do
	unless (null xs) $ putStrLn $ unlines $ "" : xs
	atomicModifyIORef ref $ \(r:rs) -> (r{total=total r+1, failures=failures r+1}:rs, ())

tested :: Bool -> IO ()
tested b = if b then passed else failed []