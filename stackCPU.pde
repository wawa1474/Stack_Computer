class stackCPU{
  boolean tosData = false;
  boolean nosData = false;
  int regTOS = 0;
  int regNOS = 0;
  int regSP = 0;
  int internalStack[] = new int[256];
  int memory[] = new int[65536]; // will be external, obviously
  
  void decodeInstruction(int opcode){
    switch(opcode){
      case 0x00: regTOS = memory[regTOS]; break; // TOS = memory[TOS]
      case 0x01: memory[popData()] = popData(); break; // memory[?OS] = ?OS (if we use T first, we can pop into it, then use N, and pop into N)
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
      internalStack[regSP] = regNOS;
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
    int tmp;
    if(tosData == true){
      tmp = regTOS;
      tosData = false;
      if(nosData == true){
        regTOS = regNOS;
        nosData = false;
        tosData = true;
          if(regSP > -1){
            regSP--;
            regNOS = internalStack[regSP];
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
}
