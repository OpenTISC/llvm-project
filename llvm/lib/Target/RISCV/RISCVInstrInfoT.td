//===-- RISCVInstrInfoT.td - TISC instructions -------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file describes the TISC instructions. Instructions supporting tagged 
// pointers.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Instruction class templates
//===----------------------------------------------------------------------===//

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
class MISC_ri<bits<3> funct3, string opcodestr>
    : RVInstI<funct3, OPC_MISC_MEM, (outs GPR:$rd), (ins GPR:$rs1, simm12:$imm12),
              opcodestr, "$rd, $rs1, $imm12">;

//===----------------------------------------------------------------------===//
// TISC Instructions
//===----------------------------------------------------------------------===//

let Predicates = [IsExplicitPointerABI] in {

def INCPI    : MISC_ri<0b100, "incpi">, Sched<[WriteIALU, ReadIALU]>;
def INCP     : ALU_rr<0b0000010, 0b100, "incp">, Sched<[WriteIALU, ReadIALU, ReadIALU]>;

def : PatGprGpr<ptradd, INCP>;
def : PatGprSimm12<ptradd, INCPI>;

def : Pat<(ptrtoint GPR:$rs1), (COPY GPR:$rs1)>;
def : Pat<(inttoptr GPR:$rs1), (COPY GPR:$rs1)>;

/// FrameIndex calculations

def : Pat<(add (i32 AddrFI:$Rs), simm12:$imm12),
          (INCPI (i32 AddrFI:$Rs), simm12:$imm12)>;
def : Pat<(IsOrAdd (i32 AddrFI:$Rs), simm12:$imm12),
          (INCPI (i32 AddrFI:$Rs), simm12:$imm12)>;

/// Explicit Pointer Loads/Stores
def LEP    : Load_ri<0b111, "lep">, Sched<[WriteLDEP, ReadMemBase]>;
def SEP    : Store_rri<0b111, "sep">, Sched<[WriteSTEP, ReadStoreData, ReadMemBase]>;

def PseudoLEP  : PseudoLoad<"lep">;
def PseudoSEP  : PseudoStore<"sep">;

def : InstAlias<"lep $rd, (${rs1})",
                (LEP  GPR:$rd, GPR:$rs1, 0)>;
def : InstAlias<"sep $rs2, (${rs1})",
                (SEP  GPR:$rs2, GPR:$rs1, 0)>;

defm : LdPat<loadiptr, LEP, iPTR>;
defm : StPat<storeiptr, SEP, GPR, iPTR>;
}
