(require '[clojure.java.io :as io]
         '[clojure.string :as str])

(defn update-stats [s temp]
  (if s
    {:min (min (:min s) temp)
     :max (max (:max s) temp)
     :total (+ (:total s) temp)
     :count (inc (:count s))}
    {:min temp :max temp :total temp :count 1}))

(with-open [rdr (io/reader "../../data/measurements.txt")]
  (let [stats (reduce
               (fn [acc line]
                 (let [[city temp] (str/split line #";")
                       temp (Long/parseLong (str/replace temp "." ""))]
                   (update acc city update-stats temp)))
               {}
               (line-seq rdr))]
    (doseq [[city s] (sort-by key stats)]
      (println (str city "\t" (:min s) "\t" (:max s) "\t" (:total s) "\t" (:count s))))))
