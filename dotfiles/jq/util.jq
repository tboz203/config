# given an array of objects all having the same keys, produce an object with those keys mapping to arrays of values
def collect:
  map(to_entries[]) | group_by(.key) | map({"key": .[0].key, "value": map(.value)}) | from_entries;

# given an array of items, produce an array of [count, distinct item] pairs
def counts:
   group_by(.) | map([length, .[0]]);

# given an array of items, produce an object mapping distinct stringified values to counts
def countmap:
   group_by(.) | map({"key": .[0] | tostring, "value": length}) | from_entries;
