# Architecture

`tif` creates an on disk index of each file in `O(n)`. 

During the index creation process the index is created in a temporary directory under 
the following structure.

```shell
.tif
--- evaluations
------ b5bb9d8014a0f9b1d61e21e796d78dccdf1352f23cd32812f4850b878ae4944c
--------- tmp
------------ aec070645fe53ee3b3763059376134f058cc337247c978add178b6ccdfb0019f
------------ 1366ad240a120f1ec3f484ae551eeac99d1d62f36e0d9cb1e68010ca38d748a1
------ 7d865e959b2466918c9863afca942d0fb89d7c9ac0c99bafc3749504ded97730
--------- tmp
------------ 2f72cc11a6fcd0271ecef8c61056ee1eb1243be3805bf9a9df98f92f7636b05c
------------ 0d6543d4937833b012c9f2da1bea863e9b4310bac5f58176a5b410041bce84fe
------ ...
--- index
```
