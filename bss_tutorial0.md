<!--
vim:set ai si sts=2 sw=2 et tw=79:
-->
# Tutorial for `bss` for snapshot timing choices

Here are typical configuration for snapshot timing choices.

## Private data

For private data, you want to keep old data.

```data
BSS_NMIN="10"  # NMIN: minimum items to keep (initial) **
BSS_NMAX="0"  # NMAX: maximum items to keep (last, if 0, keep all)
BSS_TMAX="60*60*24*150"  # TMAX: stop aging, 1000.00:00:00
BSS_TMID="60*60*24*20"  # TMID: start process,  2.00:00:00 **
BSS_TMIN="60*10*24*2"  # TMIN: start aging,  0.00:10:00 **
BSS_STEP="20"  # STEP: aging step 20 %, 200.00:00:00 at BSS_TMAX
BSS_TMAX_ACTION="keep"  # TMAX_ACTION: action at TMAX.  'keep' or 'drop'
BSS_TMID_ACTION="no_filter"  # TMID_ACTION: action at TMID.  'filter' or 'no_filter'
BSS_FMIN="10"  # FMIN: minimum required free disk % for snapshot
```

After `TMAX = 150 days`, data is retained with step:

`BSS_TMAX * BSS_STEP/100 = 150days *20/100 = 30 days`


## Public data (git repositories etc.)

For public data shared also at remote location, you don't want to keep old data.

```data
BSS_NMIN="3"  # NMIN: minimum items to keep (initial)
BSS_NMAX="0"  # NMAX: maximum items to keep (last, if 0, keep all)
BSS_TMAX="60*60*24*100"  # TMAX: stop aging, 100.00:00:00
BSS_TMID="60*60*24*2"  # TMID: start process,  2.00:00:00
BSS_TMIN="60*10"  # TMIN: start aging,  0.00:10:00
BSS_STEP="20"  # STEP: aging step 20 %, initially 200.00:00:00
BSS_TMAX_ACTION="drop"  # TMAX_ACTION: action at TMAX.  'keep' or 'drop'
BSS_TMID_ACTION="no_filter"  # TMID_ACTION: action at TMID.  'filter' or 'no_filter'
BSS_FMIN="10"  # FMIN: minimum required free disk % for snapshot
```

After `TMAX = 100 days`, data is dropped.
