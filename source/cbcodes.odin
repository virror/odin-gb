package main

import "core:fmt"

cbcodes: [256]Opcode = {
    {CB00, 2, 0,   "RLC B"},
    {CB01, 2, 0,   "RLC C"},
    {CB02, 2, 0,   "RLC D"},
    {CB03, 2, 0,   "RLC E"},
    {CB04, 2, 0,   "RLC H"},
    {CB05, 2, 0,   "RLC L"},
    {CB06, 4, 0,   "RLC (HL)"},
    {CB07, 2, 0,   "RLC A"},
    {CB08, 2, 0,   "RRC B"},
    {CB09, 2, 0,   "RRC C"},
    {CB0A, 2, 0,   "RRC D"},
    {CB0B, 2, 0,   "RRC E"},
    {CB0C, 2, 0,   "RRC H"},
    {CB0D, 2, 0,   "RRC L"},
    {CB0E, 4, 0,   "RRC (HL)"},
    {CB0F, 2, 0,   "RRC A"},
    {CB10, 2, 0,   "RL B"},
    {CB11, 2, 0,   "RL C"},
    {CB12, 2, 0,   "RL D"},
    {CB13, 2, 0,   "RL E"},
    {CB14, 2, 0,   "RL H"},
    {CB15, 2, 0,   "RL L"},
    {CB16, 4, 0,   "RL (HL)"},
    {CB17, 2, 0,   "RL A"},
    {CB18, 2, 0,   "RR B"},
    {CB19, 2, 0,   "RR C"},
    {CB1A, 2, 0,   "RR D"},
    {CB1B, 2, 0,   "RR E"},
    {CB1C, 2, 0,   "RR H"},
    {CB1D, 2, 0,   "RR L"},
    {CB1E, 4, 0,   "RR (HL)"},
    {CB1F, 2, 0,   "RR A"},
    {CB20, 2, 0,   "SLA B"},
    {CB21, 2, 0,   "SLA C"},
    {CB22, 2, 0,   "SLA D"},
    {CB23, 2, 0,   "SLA E"},
    {CB24, 2, 0,   "SLA H"},
    {CB25, 2, 0,   "SLA L"},
    {CB26, 4, 0,   "SLA (HL)"},
    {CB27, 2, 0,   "SLA A"},
    {CB28, 2, 0,   "SRA B"},
    {CB29, 2, 0,   "SRA C"},
    {CB2A, 2, 0,   "SRA D"},
    {CB2B, 2, 0,   "SRA E"},
    {CB2C, 2, 0,   "SRA H"},
    {CB2D, 2, 0,   "SRA L"},
    {CB2E, 4, 0,   "SRA (HL)"},
    {CB2F, 2, 0,   "SRA A"},
    {CB30, 2, 0,   "SWAP B"},
    {CB31, 2, 0,   "SWAP C"},
    {CB32, 2, 0,   "SWAP D"},
    {CB33, 2, 0,   "SWAP E"},
    {CB34, 2, 0,   "SWAP H"},
    {CB35, 2, 0,   "SWAP L"},
    {CB36, 4, 0,   "SWAP (HL)"},
    {CB37, 2, 0,   "SWAP A"},
    {CB38, 2, 0,   "SRL B"},
    {CB39, 2, 0,   "SRL C"},
    {CB3A, 2, 0,   "SRL D"},
    {CB3B, 2, 0,   "SRL E"},
    {CB3C, 2, 0,   "SRL H"},
    {CB3D, 2, 0,   "SRL L"},
    {CB3E, 4, 0,   "SRL (HL)"},
    {CB3F, 2, 0,   "SRL A"},
    {CB40, 2, 0,   "BIT 0, B"},
    {CB41, 2, 0,   "BIT 0, C"},
    {CB42, 2, 0,   "BIT 0, D"},
    {CB43, 2, 0,   "BIT 0, E"},
    {CB44, 2, 0,   "BIT 0, H"},
    {CB45, 2, 0,   "BIT 0, L"},
    {CB46, 3, 0,   "BIT 0, (HL)"},
    {CB47, 2, 0,   "BIT 0, A"},
    {CB48, 2, 0,   "BIT 1, B"},
    {CB49, 2, 0,   "BIT 1, C"},
    {CB4A, 2, 0,   "BIT 1, D"},
    {CB4B, 2, 0,   "BIT 1, E"},
    {CB4C, 2, 0,   "BIT 1, H"},
    {CB4D, 2, 0,   "BIT 1, L"},
    {CB4E, 3, 0,   "BIT 1, (HL)"},
    {CB4F, 2, 0,   "BIT 1, A"},
    {CB50, 2, 0,   "BIT 2, B"},
    {CB51, 2, 0,   "BIT 2, C"},
    {CB52, 2, 0,   "BIT 2, D"},
    {CB53, 2, 0,   "BIT 2, E"},
    {CB54, 2, 0,   "BIT 2, H"},
    {CB55, 2, 0,   "BIT 2, L"},
    {CB56, 3, 0,   "BIT 2, (HL)"},
    {CB57, 2, 0,   "BIT 2, A"},
    {CB58, 2, 0,   "BIT 3, B"},
    {CB59, 2, 0,   "BIT 3, C"},
    {CB5A, 2, 0,   "BIT 3, D"},
    {CB5B, 2, 0,   "BIT 3, E"},
    {CB5C, 2, 0,   "BIT 3, H"},
    {CB5D, 2, 0,   "BIT 3, L"},
    {CB5E, 3, 0,   "BIT 3, (HL)"},
    {CB5F, 2, 0,   "BIT 3, A"},
    {CB60, 2, 0,   "BIT 4, B"},
    {CB61, 2, 0,   "BIT 4, C"},
    {CB62, 2, 0,   "BIT 4, D"},
    {CB63, 2, 0,   "BIT 4, E"},
    {CB64, 2, 0,   "BIT 4, H"},
    {CB65, 2, 0,   "BIT 4, L"},
    {CB66, 3, 0,   "BIT 4, (HL)"},
    {CB67, 2, 0,   "BIT 4, A"},
    {CB68, 2, 0,   "BIT 5, B"},
    {CB69, 2, 0,   "BIT 5, C"},
    {CB6A, 2, 0,   "BIT 5, D"},
    {CB6B, 2, 0,   "BIT 5, E"},
    {CB6C, 2, 0,   "BIT 5, H"},
    {CB6D, 2, 0,   "BIT 5, L"},
    {CB6E, 3, 0,   "BIT 5, (HL)"},
    {CB6F, 2, 0,   "BIT 5, A"},
    {CB70, 2, 0,   "BIT 6, B"},
    {CB71, 2, 0,   "BIT 6, C"},
    {CB72, 2, 0,   "BIT 6, D"},
    {CB73, 2, 0,   "BIT 6, E"},
    {CB74, 2, 0,   "BIT 6, H"},
    {CB75, 2, 0,   "BIT 6, L"},
    {CB76, 3, 0,   "BIT 6, (HL)"},
    {CB77, 2, 0,   "BIT 6, A"},
    {CB78, 2, 0,   "BIT 7, B"},
    {CB79, 2, 0,   "BIT 7, C"},
    {CB7A, 2, 0,   "BIT 7, D"},
    {CB7B, 2, 0,   "BIT 7, E"},
    {CB7C, 2, 0,   "BIT 7, H"},
    {CB7D, 2, 0,   "BIT 7, L"},
    {CB7E, 3, 0,   "BIT 7, (HL)"},
    {CB7F, 2, 0,   "BIT 7, A"},
    {CB80, 2, 0,   "RES 0, B"},
    {CB81, 2, 0,   "RES 0, C"},
    {CB82, 2, 0,   "RES 0, D"},
    {CB83, 2, 0,   "RES 0, E"},
    {CB84, 2, 0,   "RES 0, H"},
    {CB85, 2, 0,   "RES 0, L"},
    {CB86, 4, 0,   "RES 0, (HL)"},
    {CB87, 2, 0,   "RES 0, A"},
    {CB88, 2, 0,   "RES 1, B"},
    {CB89, 2, 0,   "RES 1, C"},
    {CB8A, 2, 0,   "RES 1, D"},
    {CB8B, 2, 0,   "RES 1, E"},
    {CB8C, 2, 0,   "RES 1, H"},
    {CB8D, 2, 0,   "RES 1, L"},
    {CB8E, 4, 0,   "RES 1, (HL)"},
    {CB8F, 2, 0,   "RES 1, A"},
    {CB90, 2, 0,   "RES 2, B"},
    {CB91, 2, 0,   "RES 2, C"},
    {CB92, 2, 0,   "RES 2, D"},
    {CB93, 2, 0,   "RES 2, E"},
    {CB94, 2, 0,   "RES 2, H"},
    {CB95, 2, 0,   "RES 2, L"},
    {CB96, 4, 0,   "RES 2, (HL)"},
    {CB97, 2, 0,   "RES 2, A"},
    {CB98, 2, 0,   "RES 3, B"},
    {CB99, 2, 0,   "RES 3, C"},
    {CB9A, 2, 0,   "RES 3, D"},
    {CB9B, 2, 0,   "RES 3, E"},
    {CB9C, 2, 0,   "RES 3, H"},
    {CB9D, 2, 0,   "RES 3, L"},
    {CB9E, 4, 0,   "RES 3, (HL)"},
    {CB9F, 2, 0,   "RES 3, A"},
    {CBA0, 2, 0,   "RES 4, B"},
    {CBA1, 2, 0,   "RES 4, C"},
    {CBA2, 2, 0,   "RES 4, D"},
    {CBA3, 2, 0,   "RES 4, E"},
    {CBA4, 2, 0,   "RES 4, H"},
    {CBA5, 2, 0,   "RES 4, L"},
    {CBA6, 4, 0,   "RES 4, (HL)"},
    {CBA7, 2, 0,   "RES 4, A"},
    {CBA8, 2, 0,   "RES 5, B"},
    {CBA9, 2, 0,   "RES 5, C"},
    {CBAA, 2, 0,   "RES 5, D"},
    {CBAB, 2, 0,   "RES 5, E"},
    {CBAC, 2, 0,   "RES 5, H"},
    {CBAD, 2, 0,   "RES 5, L"},
    {CBAE, 4, 0,   "RES 5, (HL)"},
    {CBAF, 2, 0,   "RES 5, A"},
    {CBB0, 2, 0,   "RES 6, B"},
    {CBB1, 2, 0,   "RES 6, C"},
    {CBB2, 2, 0,   "RES 6, D"},
    {CBB3, 2, 0,   "RES 6, E"},
    {CBB4, 2, 0,   "RES 6, H"},
    {CBB5, 2, 0,   "RES 6, L"},
    {CBB6, 4, 0,   "RES 6, (HL)"},
    {CBB7, 2, 0,   "RES 6, A"},
    {CBB8, 2, 0,   "RES 7, B"},
    {CBB9, 2, 0,   "RES 7, C"},
    {CBBA, 2, 0,   "RES 7, D"},
    {CBBB, 2, 0,   "RES 7, E"},
    {CBBC, 2, 0,   "RES 7, H"},
    {CBBD, 2, 0,   "RES 7, L"},
    {CBBE, 4, 0,   "RES 7, (HL)"},
    {CBBF, 2, 0,   "RES 7, A"},
    {CBC0, 2, 0,   "SET 0, B"},
    {CBC1, 2, 0,   "SET 0, C"},
    {CBC2, 2, 0,   "SET 0, D"},
    {CBC3, 2, 0,   "SET 0, E"},
    {CBC4, 2, 0,   "SET 0, H"},
    {CBC5, 2, 0,   "SET 0, L"},
    {CBC6, 4, 0,   "SET 0, (HL)"},
    {CBC7, 2, 0,   "SET 0, A"},
    {CBC8, 2, 0,   "SET 1, B"},
    {CBC9, 2, 0,   "SET 1, C"},
    {CBCA, 2, 0,   "SET 1, D"},
    {CBCB, 2, 0,   "SET 1, E"},
    {CBCC, 2, 0,   "SET 1, H"},
    {CBCD, 2, 0,   "SET 1, L"},
    {CBCE, 4, 0,   "SET 1, (HL)"},
    {CBCF, 2, 0,   "SET 1, A"},
    {CBD0, 2, 0,   "SET 2, B"},
    {CBD1, 2, 0,   "SET 2, C"},
    {CBD2, 2, 0,   "SET 2, D"},
    {CBD3, 2, 0,   "SET 2, E"},
    {CBD4, 2, 0,   "SET 2, H"},
    {CBD5, 2, 0,   "SET 2, L"},
    {CBD6, 4, 0,   "SET 2, (HL)"},
    {CBD7, 2, 0,   "SET 2, A"},
    {CBD8, 2, 0,   "SET 3, B"},
    {CBD9, 2, 0,   "SET 3, C"},
    {CBDA, 2, 0,   "SET 3, D"},
    {CBDB, 2, 0,   "SET 3, E"},
    {CBDC, 2, 0,   "SET 3, H"},
    {CBDD, 2, 0,   "SET 3, L"},
    {CBDE, 4, 0,   "SET 3, (HL)"},
    {CBDF, 2, 0,   "SET 3, A"},
    {CBE0, 2, 0,   "SET 4, B"},
    {CBE1, 2, 0,   "SET 4, C"},
    {CBE2, 2, 0,   "SET 4, D"},
    {CBE3, 2, 0,   "SET 4, E"},
    {CBE4, 2, 0,   "SET 4, H"},
    {CBE5, 2, 0,   "SET 4, L"},
    {CBE6, 4, 0,   "SET 4, (HL)"},
    {CBE7, 2, 0,   "SET 4, A"},
    {CBE8, 2, 0,   "SET 5, B"},
    {CBE9, 2, 0,   "SET 5, C"},
    {CBEA, 2, 0,   "SET 5, D"},
    {CBEB, 2, 0,   "SET 5, E"},
    {CBEC, 2, 0,   "SET 5, H"},
    {CBED, 2, 0,   "SET 5, L"},
    {CBEE, 4, 0,   "SET 5, (HL)"},
    {CBEF, 2, 0,   "SET 5, A"},
    {CBF0, 2, 0,   "SET 6, B"},
    {CBF1, 2, 0,   "SET 6, C"},
    {CBF2, 2, 0,   "SET 6, D"},
    {CBF3, 2, 0,   "SET 6, E"},
    {CBF4, 2, 0,   "SET 6, H"},
    {CBF5, 2, 0,   "SET 6, L"},
    {CBF6, 4, 0,   "SET 6, (HL)"},
    {CBF7, 2, 0,   "SET 6, A"},
    {CBF8, 2, 0,   "SET 7, B"},
    {CBF9, 2, 0,   "SET 7, C"},
    {CBFA, 2, 0,   "SET 7, D"},
    {CBFB, 2, 0,   "SET 7, E"},
    {CBFC, 2, 0,   "SET 7, H"},
    {CBFD, 2, 0,   "SET 7, L"},
    {CBFE, 4, 0,   "SET 7, (HL)"},
    {CBFF, 2, 0,   "SET 7, A"},

}
CB47 :: proc() {
    BITx(0, Index.A)
}
CB4F :: proc() {
    BITx(1, Index.A)
}
CB57 :: proc() {
    BITx(2, Index.A)
}
CB5F :: proc() {
    BITx(3, Index.A)
}
CB67 :: proc() {
    BITx(4, Index.A)
}
CB6F :: proc() {
    BITx(5, Index.A)
}
CB77 :: proc() {
    BITx(6, Index.A)
}
CB7F :: proc() {
    BITx(7, Index.A)
}

CB40 :: proc() {
    BITx(0, Index.B)
}
CB48 :: proc() {
    BITx(1, Index.B)
}
CB50 :: proc() {
    BITx(2, Index.B)
}
CB58 :: proc() {
    BITx(3, Index.B)
}
CB60 :: proc() {
    BITx(4, Index.B)
}
CB68 :: proc() {
    BITx(5, Index.B)
}
CB70 :: proc() {
    BITx(6, Index.B)
}
CB78 :: proc() {
    BITx(7, Index.B)
}

CB41 :: proc() {
    BITx(0, Index.C)
}
CB49 :: proc() {
    BITx(1, Index.C)
}
CB51 :: proc() {
    BITx(2, Index.C)
}
CB59 :: proc() {
    BITx(3, Index.C)
}
CB61 :: proc() {
    BITx(4, Index.C)
}
CB69 :: proc() {
    BITx(5, Index.C)
}
CB71 :: proc() {
    BITx(6, Index.C)
}

CB79 :: proc() {
    BITx(7, Index.C)
}

CB42 :: proc() {
    BITx(0, Index.D)
}
CB4A :: proc() {
    BITx(1, Index.D)
}
CB52 :: proc() {
    BITx(2, Index.D)
}
CB5A :: proc() {
    BITx(3, Index.D)
}
CB62 :: proc() {
    BITx(4, Index.D)
}
CB6A :: proc() {
    BITx(5, Index.D)
}
CB72 :: proc() {
    BITx(6, Index.D)
}
CB7A :: proc() {
    BITx(7, Index.D)
}

CB43 :: proc() {
    BITx(0, Index.E)
}
CB4B :: proc() {
    BITx(1, Index.E)
}
CB53 :: proc() {
    BITx(2, Index.E)
}
CB5B :: proc() {
    BITx(3, Index.E)
}
CB63 :: proc() {
    BITx(4, Index.E)
}
CB6B :: proc() {
    BITx(5, Index.E)
}
CB73 :: proc() {
    BITx(6, Index.E)
}
CB7B :: proc() {
    BITx(7, Index.E)
}


CB44 :: proc() {
    BITx(0, Index.H)
}
CB4C :: proc() {
    BITx(1, Index.H)
}
CB54 :: proc() {
    BITx(2, Index.H)
}
CB5C :: proc() {
    BITx(3, Index.H)
}
CB64 :: proc() {
    BITx(4, Index.H)
}
CB6C :: proc() {
    BITx(5, Index.H)
}
CB74 :: proc() {
    BITx(6, Index.H)
}
CB7C :: proc() {
    BITx(7, Index.H)
}

CB45 :: proc() {
    BITx(0, Index.L)
}
CB4D :: proc() {
    BITx(1, Index.L)
}
CB55 :: proc() {
    BITx(2, Index.L)
}
CB5D :: proc() {
    BITx(3, Index.L)
}
CB65 :: proc() {
    BITx(4, Index.L)
}
CB6D :: proc() {
    BITx(5, Index.L)
}
CB75 :: proc() {
    BITx(6, Index.L)
}
CB7D :: proc() {
    BITx(7, Index.L)
}

CB46 :: proc() {
    BITx(0, Index.HL)
}
CB4E :: proc() {
    BITx(1, Index.HL)
}
CB56 :: proc() {
    BITx(2, Index.HL)
}
CB5E :: proc() {
    BITx(3, Index.HL)
}
CB66 :: proc() {
    BITx(4, Index.HL)
}
CB6E :: proc() {
    BITx(5, Index.HL)
}
CB76 :: proc() {
    BITx(6, Index.HL)
}
CB7E :: proc() {
    BITx(7, Index.HL)
}

CB87 :: proc() {
    RESx(0, Index.A)
}
CB8F :: proc() {
    RESx(1, Index.A)
}
CB97 :: proc() {
    RESx(2, Index.A)
}
CB9F :: proc() {
    RESx(3, Index.A)
}
CBA7 :: proc() {
    RESx(4, Index.A)
}
CBAF :: proc() {
    RESx(5, Index.A)
}
CBB7 :: proc() {
    RESx(6, Index.A)
}
CBBF :: proc() {
    RESx(7, Index.A)
}

CB80 :: proc() {
    RESx(0, Index.B)
}
CB88 :: proc() {
    RESx(1, Index.B)
}
CB90 :: proc() {
    RESx(2, Index.B)
}
CB98 :: proc() {
    RESx(3, Index.B)
}
CBA0 :: proc() {
    RESx(4, Index.B)
}
CBA8 :: proc() {
    RESx(5, Index.B)
}
CBB0 :: proc() {
    RESx(6, Index.B)
}
CBB8 :: proc() {
    RESx(7, Index.B)
}

CB81 :: proc() {
    RESx(0, Index.C)
}
CB89 :: proc() {
    RESx(1, Index.C)
}
CB91 :: proc() {
    RESx(2, Index.C)
}
CB99 :: proc() {
    RESx(3, Index.C)
}
CBA1 :: proc() {
    RESx(4, Index.C)
}
CBA9 :: proc() {
    RESx(5, Index.C)
}
CBB1 :: proc() {
    RESx(6, Index.C)
}
CBB9 :: proc() {
    RESx(7, Index.C)
}

CB82 :: proc() {
    RESx(0, Index.D)
}
CB8A :: proc() {
    RESx(1, Index.D)
}
CB92 :: proc() {
    RESx(2, Index.D)
}
CB9A :: proc() {
    RESx(3, Index.D)
}
CBA2 :: proc() {
    RESx(4, Index.D)
}
CBAA :: proc() {
    RESx(5, Index.D)
}
CBB2 :: proc() {
    RESx(6, Index.D)
}
CBBA :: proc() {
    RESx(7, Index.D)
}

CB83 :: proc() {
    RESx(0, Index.E)
}
CB8B :: proc() {
    RESx(1, Index.E)
}
CB93 :: proc() {
    RESx(2, Index.E)
}
CB9B :: proc() {
    RESx(3, Index.E)
}
CBA3 :: proc() {
    RESx(4, Index.E)
}
CBAB :: proc() {
    RESx(5, Index.E)
}
CBB3 :: proc() {
    RESx(6, Index.E)
}
CBBB :: proc() {
    RESx(7, Index.E)
}

CB84 :: proc() {
    RESx(0, Index.H)
}
CB8C :: proc() {
    RESx(1, Index.H)
}
CB94 :: proc() {
    RESx(2, Index.H)
}
CB9C :: proc() {
    RESx(3, Index.H)
}
CBA4 :: proc() {
    RESx(4, Index.H)
}
CBAC :: proc() {
    RESx(5, Index.H)
}
CBB4 :: proc() {
    RESx(6, Index.H)
}
CBBC :: proc() {
    RESx(7, Index.H)
}

CB85 :: proc() {
    RESx(0, Index.L)
}
CB8D :: proc() {
    RESx(1, Index.L)
}
CB95 :: proc() {
    RESx(2, Index.L)
}
CB9D :: proc() {
    RESx(3, Index.L)
}
CBA5 :: proc() {
    RESx(4, Index.L)
}
CBAD :: proc() {
    RESx(5, Index.L)
}
CBB5 :: proc() {
    RESx(6, Index.L)
}
CBBD :: proc() {
    RESx(7, Index.L)
}

CB86 :: proc() {
    RESx(0, Index.HL)
}
CB8E :: proc() {
    RESx(1, Index.HL)
}
CB96 :: proc() {
    RESx(2, Index.HL)
}
CB9E :: proc() {
    RESx(3, Index.HL)
}
CBA6 :: proc() {
    RESx(4, Index.HL)
}
CBAE :: proc() {
    RESx(5, Index.HL)
}
CBB6 :: proc() {
    RESx(6, Index.HL)
}
CBBE :: proc() {
    RESx(7, Index.HL)
}

CBC7 :: proc() {
    SETx(0, Index.A)
}
CBCF :: proc() {
    SETx(1, Index.A)
}
CBD7 :: proc() {
    SETx(2, Index.A)
}
CBDF :: proc() {
    SETx(3, Index.A)
}
CBE7 :: proc() {
    SETx(4, Index.A)
}
CBEF :: proc() {
    SETx(5, Index.A)
}
CBF7 :: proc() {
    SETx(6, Index.A)
}
CBFF :: proc() {
    SETx(7, Index.A)
}

CBC0 :: proc() {
    SETx(0, Index.B)
}
CBC8 :: proc() {
    SETx(1, Index.B)
}
CBD0 :: proc() {
    SETx(2, Index.B)
}
CBD8 :: proc() {
    SETx(3, Index.B)
}
CBE0 :: proc() {
    SETx(4, Index.B)
}
CBE8 :: proc() {
    SETx(5, Index.B)
}
CBF0 :: proc() {
    SETx(6, Index.B)
}
CBF8 :: proc() {
    SETx(7, Index.B)
}

CBC1 :: proc() {
    SETx(0, Index.C)
}
CBC9 :: proc() {
    SETx(1, Index.C)
}
CBD1 :: proc() {
    SETx(2, Index.C)
}
CBD9 :: proc() {
    SETx(3, Index.C)
}
CBE1 :: proc() {
    SETx(4, Index.C)
}
CBE9 :: proc() {
    SETx(5, Index.C)
}
CBF1 :: proc() {
    SETx(6, Index.C)
}
CBF9 :: proc() {
    SETx(7, Index.C)
}

CBC2 :: proc() {
    SETx(0, Index.D)
}
CBCA :: proc() {
    SETx(1, Index.D)
}
CBD2 :: proc() {
    SETx(2, Index.D)
}
CBDA :: proc() {
    SETx(3, Index.D)
}
CBE2 :: proc() {
    SETx(4, Index.D)
}
CBEA :: proc() {
    SETx(5, Index.D)
}
CBF2 :: proc() {
    SETx(6, Index.D)
}
CBFA :: proc() {
    SETx(7, Index.D)
}

CBC3 :: proc() {
    SETx(0, Index.E)
}
CBCB :: proc() {
    SETx(1, Index.E)
}
CBD3 :: proc() {
    SETx(2, Index.E)
}
CBDB :: proc() {
    SETx(3, Index.E)
}
CBE3 :: proc() {
    SETx(4, Index.E)
}
CBEB :: proc() {
    SETx(5, Index.E)
}
CBF3 :: proc() {
    SETx(6, Index.E)
}
CBFB :: proc() {
    SETx(7, Index.E)
}

CBC4 :: proc() {
    SETx(0, Index.H)
}
CBCC :: proc() {
    SETx(1, Index.H)
}
CBD4 :: proc() {
    SETx(2, Index.H)
}
CBDC :: proc() {
    SETx(3, Index.H)
}
CBE4 :: proc() {
    SETx(4, Index.H)
}
CBEC :: proc() {
    SETx(5, Index.H)
}
CBF4 :: proc() {
    SETx(6, Index.H)
}
CBFC :: proc() {
    SETx(7, Index.H)
}

CBC5 :: proc() {
    SETx(0, Index.L)
}
CBCD :: proc() {
    SETx(1, Index.L)
}
CBD5 :: proc() {
    SETx(2, Index.L)
}
CBDD :: proc() {
    SETx(3, Index.L)
}
CBE5 :: proc() {
    SETx(4, Index.L)
}
CBED :: proc() {
    SETx(5, Index.L)
}
CBF5 :: proc() {
    SETx(6, Index.L)
}
CBFD :: proc() {
    SETx(7, Index.L)
}

CBC6 :: proc() {
    SETx(0, Index.HL)
}
CBCE :: proc() {
    SETx(1, Index.HL)
}
CBD6 :: proc() {
    SETx(2, Index.HL)
}
CBDE :: proc() {
    SETx(3, Index.HL)
}
CBE6 :: proc() {
    SETx(4, Index.HL)
}
CBEE :: proc() {
    SETx(5, Index.HL)
}
CBF6 :: proc() {
    SETx(6, Index.HL)
}
CBFE :: proc() {
    SETx(7, Index.HL)
}

CB07 :: proc() {
    RLCx(Index.A)
}
CB00 :: proc() {
    RLCx(Index.B)
}
CB01 :: proc() {
    RLCx(Index.C)
}
CB02 :: proc() {
    RLCx(Index.D)
}
CB03 :: proc() {
    RLCx(Index.E)
}
CB04 :: proc() {
    RLCx(Index.H)
}
CB05 :: proc() {
    RLCx(Index.L)
}
CB06 :: proc() {
    RLCx(Index.HL)
}

CB0F :: proc() {
    RRCx(Index.A)
}
CB08 :: proc() {
    RRCx(Index.B)
}
CB09 :: proc() {
    RRCx(Index.C)
}
CB0A :: proc() {
    RRCx(Index.D)
}
CB0B :: proc() {
    RRCx(Index.E)
}
CB0C :: proc() {
    RRCx(Index.H)
}
CB0D :: proc() {
    RRCx(Index.L)
}
CB0E :: proc() {
    RRCx(Index.HL)
}

CB17 :: proc() {
    RLx(Index.A)
}
CB10 :: proc() {
    RLx(Index.B)
}
CB11 :: proc() {
    RLx(Index.C)
}
CB12 :: proc() {
    RLx(Index.D)
}
CB13 :: proc() {
    RLx(Index.E)
}
CB14 :: proc() {
    RLx(Index.H)
}
CB15 :: proc() {
    RLx(Index.L)
}
CB16 :: proc() {
    RLx(Index.HL)
}

CB1F :: proc() {
    RRx(Index.A)
}
CB18 :: proc() {
    RRx(Index.B)
}
CB19 :: proc() {
    RRx(Index.C)
}
CB1A :: proc() {
    RRx(Index.D)
}
CB1B :: proc() {
    RRx(Index.E)
}
CB1C :: proc() {
    RRx(Index.H)
}
CB1D :: proc() {
    RRx(Index.L)
}
CB1E :: proc() {
    RRx(Index.HL)
}

CB27 :: proc() {
    SLAx(Index.A)
}
CB20 :: proc() {
    SLAx(Index.B)
}
CB21 :: proc() {
    SLAx(Index.C)
}
CB22 :: proc() {
    SLAx(Index.D)
}
CB23 :: proc() {
    SLAx(Index.E)
}
CB24 :: proc() {
    SLAx(Index.H)
}
CB25 :: proc() {
    SLAx(Index.L)
}
CB26 :: proc() {
    SLAx(Index.HL)
}

CB2F :: proc() {
    SRAx(Index.A)
}
CB28 :: proc() {
    SRAx(Index.B)
}
CB29 :: proc() {
    SRAx(Index.C)
}
CB2A :: proc() {
    SRAx(Index.D)
}
CB2B :: proc() {
    SRAx(Index.E)
}
CB2C :: proc() {
    SRAx(Index.H)
}
CB2D :: proc() {
    SRAx(Index.L)
}
CB2E :: proc() {
    SRAx(Index.HL)
}

CB37 :: proc() {
    SWAPx(Index.A)
}
CB30 :: proc() {
    SWAPx(Index.B)
}
CB31 :: proc() {
    SWAPx(Index.C)
}
CB32 :: proc() {
    SWAPx(Index.D)
}
CB33 :: proc() {
    SWAPx(Index.E)
}
CB34 :: proc() {
    SWAPx(Index.H)
}
CB35 :: proc() {
    SWAPx(Index.L)
}
CB36 :: proc() {
    SWAPx(Index.HL)
}

CB3F :: proc() {
    SRLx(Index.A)
}
CB38 :: proc() {
    SRLx(Index.B)
}
CB39 :: proc() {
    SRLx(Index.C)
}
CB3A :: proc() {
    SRLx(Index.D)
}
CB3B :: proc() {
    SRLx(Index.E)
}
CB3C :: proc() {
    SRLx(Index.H)
}
CB3D :: proc() {
    SRLx(Index.L)
}
CB3E :: proc() {
    SRLx(Index.HL)
}

//RLC x
RLCx :: proc(index: Index) {
    if(state.cycle == 2) {
        state.value = u16(getReg(index))
    }
    if(state.cycle == 3 || state.op.cycles == 2) {
        newValue := u8(state.value << 1) //Shift
        newValue |= (u8(state.value & 0x80) >> 7)
        setReg(index, newValue)
        SetFlags(newValue, bit_test(u8(state.value), 7))
    }
}

//RRC x
RRCx :: proc(index: Index) {
    if(state.cycle == 2) {
        state.value = u16(getReg(index))
    }
    if(state.cycle == 3 || state.op.cycles == 2) {
        newValue := (u8(state.value) >> 1) //Shift
        newValue |= ((u8(state.value) & 1) << 7)
        setReg(index, newValue)
        SetFlags(newValue, bit_test(u8(state.value), 0))
    }
}

//SLA x
SLAx :: proc(index: Index) {
    if(state.cycle == 2) {
        state.value = u16(getReg(index))
    }
    if(state.cycle == 3 || state.op.cycles == 2) {
        newValue := (u8(state.value) << 1) //Shift
        setReg(index, newValue)
        SetFlags(newValue, bit_test(u8(state.value), 7))
    }
}

//SRA x
SRAx :: proc(index: Index) {
    if(state.cycle == 2) {
        state.value = u16(getReg(index))
    }
    if(state.cycle == 3 || state.op.cycles == 2) {
        newValue := (u8(state.value) >> 1) //Shift
        newValue |= (u8(state.value) & 0x80)
        setReg(index, newValue)
        SetFlags(newValue, bit_test(u8(state.value), 0))
    }
}

//RL x
RLx :: proc(index: Index) {
    if(state.cycle == 2) {
        state.value = u16(getReg(index))
    }
    if(state.cycle == 3 || state.op.cycles == 2) {
        newValue := (u8(state.value) << 1) //Shift
        newValue |= (reg.F.C?1:0) //Add carry
        setReg(index, newValue)
        SetFlags(newValue, bit_test(u8(state.value), 7))
    }
}

//RR x
RRx :: proc(index: Index) {
    if(state.cycle == 2) {
        state.value = u16(getReg(index))
    }
    if(state.cycle == 3 || state.op.cycles == 2) {
        newValue := (u8(state.value) >> 1) //Shift
        newValue |= (reg.F.C?0x80:0) //Add carry
        setReg(index, newValue)
        SetFlags(newValue, bit_test(u8(state.value), 0))
    }
}

//BIT b, x
BITx :: proc(bit: u8, index: Index) {
    reg.F.Z = !bit_test(getReg(index), bit)
    reg.F.H = true
    reg.F.N = false
}

//SET b, x
SETx :: proc(bit: u8, index: Index) {
    if(state.cycle == 2) {
        state.value = u16(getReg(index) | (1 << bit))
    }
    if(state.cycle == 3 || state.op.cycles == 2) {
        setReg(index, u8(state.value))
    }
}

//RES b, x
RESx :: proc(bit: u8, index: Index) {
    if(state.cycle == 2) {
        state.value = u16(getReg(index) & ~(1 << bit))
    }
    if(state.cycle == 3 || state.op.cycles == 2) {
        setReg(index, u8(state.value))
    }
}

//SWAP x
SWAPx :: proc(index: Index) {
    if(state.cycle == 2) {
        state.value = u16(getReg(index))
    }
    if(state.cycle == 3 || state.op.cycles == 2) {
        nibble1 := (u8(state.value & 0x0F) << 4)
        nibble2 := (u8(state.value & 0xF0) >> 4)
        newValue := (nibble1 | nibble2)
        setReg(index, newValue)
        SetFlags(newValue, false)
    }
}

//SRL x
SRLx :: proc(index: Index) {
    if(state.cycle == 2) {
        state.value = u16(getReg(index))
    }
    if(state.cycle == 3 || state.op.cycles == 2) {
        newValue := (u8(state.value) >> 1) //Shift
        setReg(index, newValue)
        SetFlags(newValue, bit_test(u8(state.value), 0))
    }
}

SetFlags :: proc(newValue: u8, carry: bool) {
    reg.F.Z = newValue == 0
    reg.F.N = false
    reg.F.H = false
    reg.F.C = carry
}