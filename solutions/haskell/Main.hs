import qualified Data.ByteString.Char8 as B
import qualified Data.Map.Strict as M

type Stats = (Int, Int, Int, Int)

main :: IO ()
main = do
  content <- B.readFile "../../data/measurements.txt"
  let stats = M.toAscList (foldl step M.empty (B.lines content))
  mapM_ printRow stats
  where
    step m line =
      let (city, rest) = B.break (== ';') line
       in if B.null rest
            then m
            else
              let value = read (B.unpack (B.filter (/= '.') (B.tail rest))) :: Int
               in M.insertWith merge city (value, value, value, 1) m
    merge (nv, _, ntot, ncnt) (mn, mx, tot, cnt) =
      (min nv mn, max nv mx, ntot + tot, ncnt + cnt)
    printRow (city, (mn, mx, tot, cnt)) =
      B.putStr city
        >> putStrLn ("\t" ++ show mn ++ "\t" ++ show mx ++ "\t" ++ show tot ++ "\t" ++ show cnt)
