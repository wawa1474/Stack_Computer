static int flagTrue = 1; // may want to be all ones
static int flagFalse = 0;
static int cellMask = 0xFFFF; // how many bits is a cell? 16/32?
static int cellSize = 1; // how many address units is one cell, lets assume it's 1:1 (data bus width matches cell width)

class stackCPU{
  boolean tosData = false;
  boolean nosData = false;
  int regTOS = 0;
  int regNOS = 0;
  int regSP = 0;
  int internalDataStack[] = new int[256];
  int memory[] = new int[65536]; // will be external, obviously
  int tmp;
  int regRP = 0;
  int internalAddressStack[] = new int[256];
  
  void decodeInstruction(int opcode){
    switch(opcode){
      case 0x00: pokeTOS(memory[peekTOS()]); break; // @
      case 0x01: tmp = popData(); memory[tmp] = popData(); break; // !
      case 0x02: pushData(peekTOS()); break; // DUP
      case 0x03: popData(); break; // DROP
      case 0x04: pushData(peekNOS()); break; // OVER [>R DUP R> SWAP ]
      case 0x05: tmp = peekTOS(); pokeTOS(peekNOS()); pokeNOS(tmp); break; // SWAP
      case 0x06: pokeNOS(peekTOS()); popData(); break; // NIP [SWAP DROP]
      case 0x07: pushStack(peekTOS()); break; // TUCK [SWAP OVER]
      case 0x08: tmp = popData(); pokeTOS(max(tmp, peekTOS())); // MAX [2DUP < IF NIP EXIT THEN DROP]/[2DUP < IF SWAP THEN DROP]
      case 0x09: tmp = popData(); pokeTOS(min(tmp, peekTOS())); // MIN [2DUP < IF DROP EXIT THEN NIP]/[2DUP > IF SWAP THEN DROP]
      case 0x0A: pokeTOS(-peekTOS() & cellMask); // NEG
      case 0x0B: tmp = popData(); pokeTOS(tmp | peekTOS()); // OR
      case 0x0C: tmp = popData(); pokeTOS(tmp & peekTOS()); // AND
      case 0x0D: tmp = popData(); pokeTOS(tmp ^ peekTOS()); // XOR
      case 0x0E: pokeTOS(peekStackAll(peekTOS())); // PICK [dup 0= if drop dup exit then  swap >r 1- recurse r> swap] (PLACE/PUT?)
      case 0x0F: tmp = peekStack(); pokeStack(peekNOS()); pokeNOS(peekTOS()); pokeTOS(tmp); break; // ROT
      case 0x10: tmp = popData(); pokeTOS(peekTOS() << tmp); break; // LSHIFT
      case 0x11: tmp = popData(); pokeTOS(peekTOS() >>> tmp); break; // RSHIFT
      case 0x12: pushData(popAddress()); break; // R>
      case 0x13: pushAddress(popData()); break; // >R
      case 0x14: pushData(peekAddress()); break; // R@ [R> dup >R]
      case 0x15: tmp = popData(); pushAddress(popData()); pushAddress(tmp); break; // 2>R [SWAP >R >R]
      case 0x16: tmp = popAddress(); pushData(popAddress()); pushData(tmp); break; // 2R> [R> R> SWAP]
      case 0x17: pushData(peekAddressRel(1)); pushData(peekAddress()); break; // 2R@ [R> R> 2DUP >R >R SWAP]
      case 0x18: pokeTOS(memory[peekTOS()] & 0xFF); break; // C@
      case 0x19: tmp = popData(); memory[tmp] = popData() & 0xFF; break; // C!
      case 0x1A: tmp = popData(); pokeTOS(tmp == peekTOS() ? flagTrue : flagFalse); break; // =
      case 0x1B: pokeTOS(peekTOS() == 0 ? flagTrue : flagFalse); break; // 0= [0 =]
      case 0x1C: pokeTOS(peekTOS() < 0 ? flagTrue : flagFalse); break; // 0< [0 <]
      case 0x1D: pokeTOS(peekTOS() > 0 ? flagTrue : flagFalse); break; // 0> [0 >]
      case 0x1E: pokeTOS(peekTOS() != 0 ? flagTrue : flagFalse); break; // 0<> [0 <>]
      case 0x1F: pokeTOS(peekTOS() + 1); break; // 1+ [1 +]
      case 0x20: pokeTOS(peekTOS() - 1); break; // 1- [1 -]
      case 0x21: pokeTOS(peekTOS() * cellSize); break; // CELLS
      case 0x22: pokeTOS(peekTOS() + cellSize); break; // CELL+
      case 0x23: tmp = popData(); pushData(memory[tmp + cellSize]); pushData(memory[tmp]); break; // 2@ [DUP CELL+ @ SWAP @]
      case 0x24: tmp = popData(); memory[tmp] = popData(); memory[tmp + cellSize] = popData(); break; // 2! [ SWAP OVER ! CELL+ !]
      case 0x25: tmp = popData(); pokeTOS(peekTOS() < tmp ? flagTrue : flagFalse); break; // <
      case 0x26: tmp = popData(); pokeTOS(peekTOS() > tmp ? flagTrue : flagFalse); break; // >
      case 0x27: tmp = popData(); pokeTOS(peekTOS() != tmp ? flagTrue : flagFalse); break; // <>
      case 0x28: pokeTOS(~peekTOS() & cellMask); // INVERT
    }
  }
  
  void pushData(int data){
    if(tosData == false){
      regTOS = data;
      tosData = true;
    }else if(nosData == false){
      regNOS = regTOS;
      regTOS = data;
      nosData = true;
      tosData = true;
    }else if(regSP < 256){
      internalDataStack[regSP] = regNOS;
      regNOS = regTOS;
      regTOS = data;
      regSP++;
      nosData = true;
      tosData = true;
    }else{
      // ThrowError("Stack Overflow!");
    }
  }
  
  int popData(){
    if(tosData == true){
      tmp = regTOS;
      tosData = false;
      if(nosData == true){
        regTOS = regNOS;
        nosData = false;
        tosData = true;
          if(regSP > 0){
            regSP--;
            regNOS = internalDataStack[regSP];
            nosData = true;
          }
      }
      return tmp;
    }else{
      // ThrowError("Stack Underflow!");
      return -1;
    }
  }
  
  //int popData2(){} // would be more efficient, but require extra stuff
  
  int peekTOS(){
    if(tosData == true){
      tosData = false;
      return regTOS;
    }else{
      // ThrowError("Stack Underflow!");
      return -1;
    }
  }
  
  int peekNOS(){
    if(nosData == true){
      nosData = false;
      return regNOS;
    }else{
      // ThrowError("Stack Underflow!");
      return -1;
    }
  }
  
  int peekStackAll(int address){
    if(address == 0){
      return peekTOS();
    }else if(address == 1){
      return peekNOS();
    }else if(regSP > (address - 2)){
      return internalDataStack[address - 2];
    }else{
      // ThrowError("Stack Underflow!");
      return -1;
    }
  }
  
  int peekStack(int address){
    if(regSP > address){
      return internalDataStack[address];
    }else{
      // ThrowError("Stack Underflow!");
      return -1;
    }
  }
  
  void pokeTOS(int data){
    regTOS = data;
    if(tosData == false){
      tosData = true;
    }
  }
  
  void pokeNOS(int data){
    regNOS = data;
    if(nosData == false){
      nosData = true;
    }
  }
  
  void pushStack(int data){
    if(regSP < 256){
      internalDataStack[regSP] = data;
      regSP++;
    }else{
      // ThrowError("Stack Overflow!");
    }
  }
  
  int peekStack(){
    if(regSP > 0){
      return internalDataStack[regSP - 1];
    }else{
      // ThrowError("Stack Underflow!");
      return -1;
    }
  }
  
  void pokeStack(int data){
    if(regSP > 0){
      internalDataStack[regSP - 1] = data;
    }else{
      // ThrowError("Stack Underflow!");
    }
  }
  
  int popStack(){
    if(regSP > 0){
      regSP--;
      return internalDataStack[regSP];
    }else{
      // ThrowError("Stack Underflow!");
      return -1;
    }
  }
  
  void pushAddress(int data){
    if(regRP < 256){
      internalAddressStack[regSP] = data;
      regSP++;
    }else{
      // ThrowError("Stack Overflow!");
    }
  }
  
  int popAddress(){
    if(regRP > 0){
      regSP--;
      return internalAddressStack[regSP];
    }else{
      // ThrowError("Stack Underflow!");
      return -1;
    }
  }
  
  int peekAddress(){
    if(regRP > 0){
      return internalAddressStack[regSP - 1];
    }else{
      // ThrowError("Stack Underflow!");
      return -1;
    }
  }
  
  int peekAddressRel(int address){
    if(regRP > address){
      return internalAddressStack[regRP - address];
    }else{
      // ThrowError("Stack Underflow!");
      return -1;
    }
  }
}
