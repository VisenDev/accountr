# How to store data without using up too much memory?
- two main data directories: active and inactive
- active entity data will be loaded into memory every time
- inactive entity data will only loaded when requested
- entities that have not been accessed recently are moved to inactive

# Data storage format? 
- each set of components stored in its own `component-name.json.zstd` 
- data for each component is stored as an encrypted b64 string
- should the b64 string be a binary representation of the struct? Or a json formatted version
- binary representation pros: fast
- binary representation cons: encoding will change between zig versions, no pointers
- json pros: stable encoding, pointers to strings allowed
- json cons: potentially slower

# In memory storage format?
- should memory be encrypted? probably
- how to store in memory data then? 
