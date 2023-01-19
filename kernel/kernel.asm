
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	b4013103          	ld	sp,-1216(sp) # 80008b40 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid"
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	b4e70713          	addi	a4,a4,-1202 # 80008ba0 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0"
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0"
    80000064:	00006797          	auipc	a5,0x6
    80000068:	2cc78793          	addi	a5,a5,716 # 80006330 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus"
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0"
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie"
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0"
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus"
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdb7ef>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0"
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0"
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de678793          	addi	a5,a5,-538 # 80000e94 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0"
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0"
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0"
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie"
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0"
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0"
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0"
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid"
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void
w_tp(uint64 x)
{
  asm volatile("mv tp, %0"
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00003097          	auipc	ra,0x3
    80000130:	810080e7          	jalr	-2032(ra) # 8000293c <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	794080e7          	jalr	1940(ra) # 800008d0 <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	b5450513          	addi	a0,a0,-1196 # 80010ce0 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	b4448493          	addi	s1,s1,-1212 # 80010ce0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	bd290913          	addi	s2,s2,-1070 # 80010d78 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405b63          	blez	s4,8000022a <consoleread+0xc6>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71763          	bne	a4,a5,800001ee <consoleread+0x8a>
      if(killed(myproc())){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	802080e7          	jalr	-2046(ra) # 800019c6 <myproc>
    800001cc:	00002097          	auipc	ra,0x2
    800001d0:	5ba080e7          	jalr	1466(ra) # 80002786 <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	1ac080e7          	jalr	428(ra) # 80002386 <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fcf70de3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000204:	079c0663          	beq	s8,s9,80000270 <consoleread+0x10c>
    cbuf = c;
    80000208:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f8f40613          	addi	a2,s0,-113
    80000212:	85d6                	mv	a1,s5
    80000214:	855a                	mv	a0,s6
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	6d0080e7          	jalr	1744(ra) # 800028e6 <either_copyout>
    8000021e:	01a50663          	beq	a0,s10,8000022a <consoleread+0xc6>
    dst++;
    80000222:	0a85                	addi	s5,s5,1
    --n;
    80000224:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000226:	f9bc17e3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00011517          	auipc	a0,0x11
    8000022e:	ab650513          	addi	a0,a0,-1354 # 80010ce0 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a6c080e7          	jalr	-1428(ra) # 80000c9e <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	aa050513          	addi	a0,a0,-1376 # 80010ce0 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	a56080e7          	jalr	-1450(ra) # 80000c9e <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70e6                	ld	ra,120(sp)
    80000254:	7446                	ld	s0,112(sp)
    80000256:	74a6                	ld	s1,104(sp)
    80000258:	7906                	ld	s2,96(sp)
    8000025a:	69e6                	ld	s3,88(sp)
    8000025c:	6a46                	ld	s4,80(sp)
    8000025e:	6aa6                	ld	s5,72(sp)
    80000260:	6b06                	ld	s6,64(sp)
    80000262:	7be2                	ld	s7,56(sp)
    80000264:	7c42                	ld	s8,48(sp)
    80000266:	7ca2                	ld	s9,40(sp)
    80000268:	7d02                	ld	s10,32(sp)
    8000026a:	6de2                	ld	s11,24(sp)
    8000026c:	6109                	addi	sp,sp,128
    8000026e:	8082                	ret
      if(n < target){
    80000270:	000a071b          	sext.w	a4,s4
    80000274:	fb777be3          	bgeu	a4,s7,8000022a <consoleread+0xc6>
        cons.r--;
    80000278:	00011717          	auipc	a4,0x11
    8000027c:	b0f72023          	sw	a5,-1280(a4) # 80010d78 <cons+0x98>
    80000280:	b76d                	j	8000022a <consoleread+0xc6>

0000000080000282 <consputc>:
{
    80000282:	1141                	addi	sp,sp,-16
    80000284:	e406                	sd	ra,8(sp)
    80000286:	e022                	sd	s0,0(sp)
    80000288:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028a:	10000793          	li	a5,256
    8000028e:	00f50a63          	beq	a0,a5,800002a2 <consputc+0x20>
    uartputc_sync(c);
    80000292:	00000097          	auipc	ra,0x0
    80000296:	564080e7          	jalr	1380(ra) # 800007f6 <uartputc_sync>
}
    8000029a:	60a2                	ld	ra,8(sp)
    8000029c:	6402                	ld	s0,0(sp)
    8000029e:	0141                	addi	sp,sp,16
    800002a0:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a2:	4521                	li	a0,8
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	552080e7          	jalr	1362(ra) # 800007f6 <uartputc_sync>
    800002ac:	02000513          	li	a0,32
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	546080e7          	jalr	1350(ra) # 800007f6 <uartputc_sync>
    800002b8:	4521                	li	a0,8
    800002ba:	00000097          	auipc	ra,0x0
    800002be:	53c080e7          	jalr	1340(ra) # 800007f6 <uartputc_sync>
    800002c2:	bfe1                	j	8000029a <consputc+0x18>

00000000800002c4 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c4:	1101                	addi	sp,sp,-32
    800002c6:	ec06                	sd	ra,24(sp)
    800002c8:	e822                	sd	s0,16(sp)
    800002ca:	e426                	sd	s1,8(sp)
    800002cc:	e04a                	sd	s2,0(sp)
    800002ce:	1000                	addi	s0,sp,32
    800002d0:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d2:	00011517          	auipc	a0,0x11
    800002d6:	a0e50513          	addi	a0,a0,-1522 # 80010ce0 <cons>
    800002da:	00001097          	auipc	ra,0x1
    800002de:	910080e7          	jalr	-1776(ra) # 80000bea <acquire>

  switch(c){
    800002e2:	47d5                	li	a5,21
    800002e4:	0af48663          	beq	s1,a5,80000390 <consoleintr+0xcc>
    800002e8:	0297ca63          	blt	a5,s1,8000031c <consoleintr+0x58>
    800002ec:	47a1                	li	a5,8
    800002ee:	0ef48763          	beq	s1,a5,800003dc <consoleintr+0x118>
    800002f2:	47c1                	li	a5,16
    800002f4:	10f49a63          	bne	s1,a5,80000408 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f8:	00002097          	auipc	ra,0x2
    800002fc:	69a080e7          	jalr	1690(ra) # 80002992 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00011517          	auipc	a0,0x11
    80000304:	9e050513          	addi	a0,a0,-1568 # 80010ce0 <cons>
    80000308:	00001097          	auipc	ra,0x1
    8000030c:	996080e7          	jalr	-1642(ra) # 80000c9e <release>
}
    80000310:	60e2                	ld	ra,24(sp)
    80000312:	6442                	ld	s0,16(sp)
    80000314:	64a2                	ld	s1,8(sp)
    80000316:	6902                	ld	s2,0(sp)
    80000318:	6105                	addi	sp,sp,32
    8000031a:	8082                	ret
  switch(c){
    8000031c:	07f00793          	li	a5,127
    80000320:	0af48e63          	beq	s1,a5,800003dc <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000324:	00011717          	auipc	a4,0x11
    80000328:	9bc70713          	addi	a4,a4,-1604 # 80010ce0 <cons>
    8000032c:	0a072783          	lw	a5,160(a4)
    80000330:	09872703          	lw	a4,152(a4)
    80000334:	9f99                	subw	a5,a5,a4
    80000336:	07f00713          	li	a4,127
    8000033a:	fcf763e3          	bltu	a4,a5,80000300 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033e:	47b5                	li	a5,13
    80000340:	0cf48763          	beq	s1,a5,8000040e <consoleintr+0x14a>
      consputc(c);
    80000344:	8526                	mv	a0,s1
    80000346:	00000097          	auipc	ra,0x0
    8000034a:	f3c080e7          	jalr	-196(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000034e:	00011797          	auipc	a5,0x11
    80000352:	99278793          	addi	a5,a5,-1646 # 80010ce0 <cons>
    80000356:	0a07a683          	lw	a3,160(a5)
    8000035a:	0016871b          	addiw	a4,a3,1
    8000035e:	0007061b          	sext.w	a2,a4
    80000362:	0ae7a023          	sw	a4,160(a5)
    80000366:	07f6f693          	andi	a3,a3,127
    8000036a:	97b6                	add	a5,a5,a3
    8000036c:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000370:	47a9                	li	a5,10
    80000372:	0cf48563          	beq	s1,a5,8000043c <consoleintr+0x178>
    80000376:	4791                	li	a5,4
    80000378:	0cf48263          	beq	s1,a5,8000043c <consoleintr+0x178>
    8000037c:	00011797          	auipc	a5,0x11
    80000380:	9fc7a783          	lw	a5,-1540(a5) # 80010d78 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00011717          	auipc	a4,0x11
    80000394:	95070713          	addi	a4,a4,-1712 # 80010ce0 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00011497          	auipc	s1,0x11
    800003a4:	94048493          	addi	s1,s1,-1728 # 80010ce0 <cons>
    while(cons.e != cons.w &&
    800003a8:	4929                	li	s2,10
    800003aa:	f4f70be3          	beq	a4,a5,80000300 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003ae:	37fd                	addiw	a5,a5,-1
    800003b0:	07f7f713          	andi	a4,a5,127
    800003b4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b6:	01874703          	lbu	a4,24(a4)
    800003ba:	f52703e3          	beq	a4,s2,80000300 <consoleintr+0x3c>
      cons.e--;
    800003be:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c2:	10000513          	li	a0,256
    800003c6:	00000097          	auipc	ra,0x0
    800003ca:	ebc080e7          	jalr	-324(ra) # 80000282 <consputc>
    while(cons.e != cons.w &&
    800003ce:	0a04a783          	lw	a5,160(s1)
    800003d2:	09c4a703          	lw	a4,156(s1)
    800003d6:	fcf71ce3          	bne	a4,a5,800003ae <consoleintr+0xea>
    800003da:	b71d                	j	80000300 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003dc:	00011717          	auipc	a4,0x11
    800003e0:	90470713          	addi	a4,a4,-1788 # 80010ce0 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00011717          	auipc	a4,0x11
    800003f6:	98f72723          	sw	a5,-1650(a4) # 80010d80 <cons+0xa0>
      consputc(BACKSPACE);
    800003fa:	10000513          	li	a0,256
    800003fe:	00000097          	auipc	ra,0x0
    80000402:	e84080e7          	jalr	-380(ra) # 80000282 <consputc>
    80000406:	bded                	j	80000300 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000408:	ee048ce3          	beqz	s1,80000300 <consoleintr+0x3c>
    8000040c:	bf21                	j	80000324 <consoleintr+0x60>
      consputc(c);
    8000040e:	4529                	li	a0,10
    80000410:	00000097          	auipc	ra,0x0
    80000414:	e72080e7          	jalr	-398(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000418:	00011797          	auipc	a5,0x11
    8000041c:	8c878793          	addi	a5,a5,-1848 # 80010ce0 <cons>
    80000420:	0a07a703          	lw	a4,160(a5)
    80000424:	0017069b          	addiw	a3,a4,1
    80000428:	0006861b          	sext.w	a2,a3
    8000042c:	0ad7a023          	sw	a3,160(a5)
    80000430:	07f77713          	andi	a4,a4,127
    80000434:	97ba                	add	a5,a5,a4
    80000436:	4729                	li	a4,10
    80000438:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043c:	00011797          	auipc	a5,0x11
    80000440:	94c7a023          	sw	a2,-1728(a5) # 80010d7c <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00011517          	auipc	a0,0x11
    80000448:	93450513          	addi	a0,a0,-1740 # 80010d78 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	0ea080e7          	jalr	234(ra) # 80002536 <wakeup>
    80000454:	b575                	j	80000300 <consoleintr+0x3c>

0000000080000456 <consoleinit>:

void
consoleinit(void)
{
    80000456:	1141                	addi	sp,sp,-16
    80000458:	e406                	sd	ra,8(sp)
    8000045a:	e022                	sd	s0,0(sp)
    8000045c:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045e:	00008597          	auipc	a1,0x8
    80000462:	bb258593          	addi	a1,a1,-1102 # 80008010 <etext+0x10>
    80000466:	00011517          	auipc	a0,0x11
    8000046a:	87a50513          	addi	a0,a0,-1926 # 80010ce0 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	6ec080e7          	jalr	1772(ra) # 80000b5a <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00022797          	auipc	a5,0x22
    80000482:	9fa78793          	addi	a5,a5,-1542 # 80021e78 <devsw>
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	cde70713          	addi	a4,a4,-802 # 80000164 <consoleread>
    8000048e:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000490:	00000717          	auipc	a4,0x0
    80000494:	c7270713          	addi	a4,a4,-910 # 80000102 <consolewrite>
    80000498:	ef98                	sd	a4,24(a5)
}
    8000049a:	60a2                	ld	ra,8(sp)
    8000049c:	6402                	ld	s0,0(sp)
    8000049e:	0141                	addi	sp,sp,16
    800004a0:	8082                	ret

00000000800004a2 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a2:	7179                	addi	sp,sp,-48
    800004a4:	f406                	sd	ra,40(sp)
    800004a6:	f022                	sd	s0,32(sp)
    800004a8:	ec26                	sd	s1,24(sp)
    800004aa:	e84a                	sd	s2,16(sp)
    800004ac:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ae:	c219                	beqz	a2,800004b4 <printint+0x12>
    800004b0:	08054663          	bltz	a0,8000053c <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b4:	2501                	sext.w	a0,a0
    800004b6:	4881                	li	a7,0
    800004b8:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004bc:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004be:	2581                	sext.w	a1,a1
    800004c0:	00008617          	auipc	a2,0x8
    800004c4:	b8060613          	addi	a2,a2,-1152 # 80008040 <digits>
    800004c8:	883a                	mv	a6,a4
    800004ca:	2705                	addiw	a4,a4,1
    800004cc:	02b577bb          	remuw	a5,a0,a1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	97b2                	add	a5,a5,a2
    800004d6:	0007c783          	lbu	a5,0(a5)
    800004da:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004de:	0005079b          	sext.w	a5,a0
    800004e2:	02b5553b          	divuw	a0,a0,a1
    800004e6:	0685                	addi	a3,a3,1
    800004e8:	feb7f0e3          	bgeu	a5,a1,800004c8 <printint+0x26>

  if(sign)
    800004ec:	00088b63          	beqz	a7,80000502 <printint+0x60>
    buf[i++] = '-';
    800004f0:	fe040793          	addi	a5,s0,-32
    800004f4:	973e                	add	a4,a4,a5
    800004f6:	02d00793          	li	a5,45
    800004fa:	fef70823          	sb	a5,-16(a4)
    800004fe:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000502:	02e05763          	blez	a4,80000530 <printint+0x8e>
    80000506:	fd040793          	addi	a5,s0,-48
    8000050a:	00e784b3          	add	s1,a5,a4
    8000050e:	fff78913          	addi	s2,a5,-1
    80000512:	993a                	add	s2,s2,a4
    80000514:	377d                	addiw	a4,a4,-1
    80000516:	1702                	slli	a4,a4,0x20
    80000518:	9301                	srli	a4,a4,0x20
    8000051a:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051e:	fff4c503          	lbu	a0,-1(s1)
    80000522:	00000097          	auipc	ra,0x0
    80000526:	d60080e7          	jalr	-672(ra) # 80000282 <consputc>
  while(--i >= 0)
    8000052a:	14fd                	addi	s1,s1,-1
    8000052c:	ff2499e3          	bne	s1,s2,8000051e <printint+0x7c>
}
    80000530:	70a2                	ld	ra,40(sp)
    80000532:	7402                	ld	s0,32(sp)
    80000534:	64e2                	ld	s1,24(sp)
    80000536:	6942                	ld	s2,16(sp)
    80000538:	6145                	addi	sp,sp,48
    8000053a:	8082                	ret
    x = -xx;
    8000053c:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000540:	4885                	li	a7,1
    x = -xx;
    80000542:	bf9d                	j	800004b8 <printint+0x16>

0000000080000544 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000544:	1101                	addi	sp,sp,-32
    80000546:	ec06                	sd	ra,24(sp)
    80000548:	e822                	sd	s0,16(sp)
    8000054a:	e426                	sd	s1,8(sp)
    8000054c:	1000                	addi	s0,sp,32
    8000054e:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000550:	00011797          	auipc	a5,0x11
    80000554:	8407a823          	sw	zero,-1968(a5) # 80010da0 <pr+0x18>
  printf("panic: ");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	ac050513          	addi	a0,a0,-1344 # 80008018 <etext+0x18>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	02e080e7          	jalr	46(ra) # 8000058e <printf>
  printf(s);
    80000568:	8526                	mv	a0,s1
    8000056a:	00000097          	auipc	ra,0x0
    8000056e:	024080e7          	jalr	36(ra) # 8000058e <printf>
  printf("\n");
    80000572:	00008517          	auipc	a0,0x8
    80000576:	b5650513          	addi	a0,a0,-1194 # 800080c8 <digits+0x88>
    8000057a:	00000097          	auipc	ra,0x0
    8000057e:	014080e7          	jalr	20(ra) # 8000058e <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000582:	4785                	li	a5,1
    80000584:	00008717          	auipc	a4,0x8
    80000588:	5cf72e23          	sw	a5,1500(a4) # 80008b60 <panicked>
  for(;;)
    8000058c:	a001                	j	8000058c <panic+0x48>

000000008000058e <printf>:
{
    8000058e:	7131                	addi	sp,sp,-192
    80000590:	fc86                	sd	ra,120(sp)
    80000592:	f8a2                	sd	s0,112(sp)
    80000594:	f4a6                	sd	s1,104(sp)
    80000596:	f0ca                	sd	s2,96(sp)
    80000598:	ecce                	sd	s3,88(sp)
    8000059a:	e8d2                	sd	s4,80(sp)
    8000059c:	e4d6                	sd	s5,72(sp)
    8000059e:	e0da                	sd	s6,64(sp)
    800005a0:	fc5e                	sd	s7,56(sp)
    800005a2:	f862                	sd	s8,48(sp)
    800005a4:	f466                	sd	s9,40(sp)
    800005a6:	f06a                	sd	s10,32(sp)
    800005a8:	ec6e                	sd	s11,24(sp)
    800005aa:	0100                	addi	s0,sp,128
    800005ac:	8a2a                	mv	s4,a0
    800005ae:	e40c                	sd	a1,8(s0)
    800005b0:	e810                	sd	a2,16(s0)
    800005b2:	ec14                	sd	a3,24(s0)
    800005b4:	f018                	sd	a4,32(s0)
    800005b6:	f41c                	sd	a5,40(s0)
    800005b8:	03043823          	sd	a6,48(s0)
    800005bc:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c0:	00010d97          	auipc	s11,0x10
    800005c4:	7e0dad83          	lw	s11,2016(s11) # 80010da0 <pr+0x18>
  if(locking)
    800005c8:	020d9b63          	bnez	s11,800005fe <printf+0x70>
  if (fmt == 0)
    800005cc:	040a0263          	beqz	s4,80000610 <printf+0x82>
  va_start(ap, fmt);
    800005d0:	00840793          	addi	a5,s0,8
    800005d4:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d8:	000a4503          	lbu	a0,0(s4)
    800005dc:	16050263          	beqz	a0,80000740 <printf+0x1b2>
    800005e0:	4481                	li	s1,0
    if(c != '%'){
    800005e2:	02500a93          	li	s5,37
    switch(c){
    800005e6:	07000b13          	li	s6,112
  consputc('x');
    800005ea:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ec:	00008b97          	auipc	s7,0x8
    800005f0:	a54b8b93          	addi	s7,s7,-1452 # 80008040 <digits>
    switch(c){
    800005f4:	07300c93          	li	s9,115
    800005f8:	06400c13          	li	s8,100
    800005fc:	a82d                	j	80000636 <printf+0xa8>
    acquire(&pr.lock);
    800005fe:	00010517          	auipc	a0,0x10
    80000602:	78a50513          	addi	a0,a0,1930 # 80010d88 <pr>
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	5e4080e7          	jalr	1508(ra) # 80000bea <acquire>
    8000060e:	bf7d                	j	800005cc <printf+0x3e>
    panic("null fmt");
    80000610:	00008517          	auipc	a0,0x8
    80000614:	a1850513          	addi	a0,a0,-1512 # 80008028 <etext+0x28>
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	f2c080e7          	jalr	-212(ra) # 80000544 <panic>
      consputc(c);
    80000620:	00000097          	auipc	ra,0x0
    80000624:	c62080e7          	jalr	-926(ra) # 80000282 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000628:	2485                	addiw	s1,s1,1
    8000062a:	009a07b3          	add	a5,s4,s1
    8000062e:	0007c503          	lbu	a0,0(a5)
    80000632:	10050763          	beqz	a0,80000740 <printf+0x1b2>
    if(c != '%'){
    80000636:	ff5515e3          	bne	a0,s5,80000620 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063a:	2485                	addiw	s1,s1,1
    8000063c:	009a07b3          	add	a5,s4,s1
    80000640:	0007c783          	lbu	a5,0(a5)
    80000644:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000648:	cfe5                	beqz	a5,80000740 <printf+0x1b2>
    switch(c){
    8000064a:	05678a63          	beq	a5,s6,8000069e <printf+0x110>
    8000064e:	02fb7663          	bgeu	s6,a5,8000067a <printf+0xec>
    80000652:	09978963          	beq	a5,s9,800006e4 <printf+0x156>
    80000656:	07800713          	li	a4,120
    8000065a:	0ce79863          	bne	a5,a4,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000065e:	f8843783          	ld	a5,-120(s0)
    80000662:	00878713          	addi	a4,a5,8
    80000666:	f8e43423          	sd	a4,-120(s0)
    8000066a:	4605                	li	a2,1
    8000066c:	85ea                	mv	a1,s10
    8000066e:	4388                	lw	a0,0(a5)
    80000670:	00000097          	auipc	ra,0x0
    80000674:	e32080e7          	jalr	-462(ra) # 800004a2 <printint>
      break;
    80000678:	bf45                	j	80000628 <printf+0x9a>
    switch(c){
    8000067a:	0b578263          	beq	a5,s5,8000071e <printf+0x190>
    8000067e:	0b879663          	bne	a5,s8,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000682:	f8843783          	ld	a5,-120(s0)
    80000686:	00878713          	addi	a4,a5,8
    8000068a:	f8e43423          	sd	a4,-120(s0)
    8000068e:	4605                	li	a2,1
    80000690:	45a9                	li	a1,10
    80000692:	4388                	lw	a0,0(a5)
    80000694:	00000097          	auipc	ra,0x0
    80000698:	e0e080e7          	jalr	-498(ra) # 800004a2 <printint>
      break;
    8000069c:	b771                	j	80000628 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069e:	f8843783          	ld	a5,-120(s0)
    800006a2:	00878713          	addi	a4,a5,8
    800006a6:	f8e43423          	sd	a4,-120(s0)
    800006aa:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006ae:	03000513          	li	a0,48
    800006b2:	00000097          	auipc	ra,0x0
    800006b6:	bd0080e7          	jalr	-1072(ra) # 80000282 <consputc>
  consputc('x');
    800006ba:	07800513          	li	a0,120
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bc4080e7          	jalr	-1084(ra) # 80000282 <consputc>
    800006c6:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c8:	03c9d793          	srli	a5,s3,0x3c
    800006cc:	97de                	add	a5,a5,s7
    800006ce:	0007c503          	lbu	a0,0(a5)
    800006d2:	00000097          	auipc	ra,0x0
    800006d6:	bb0080e7          	jalr	-1104(ra) # 80000282 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006da:	0992                	slli	s3,s3,0x4
    800006dc:	397d                	addiw	s2,s2,-1
    800006de:	fe0915e3          	bnez	s2,800006c8 <printf+0x13a>
    800006e2:	b799                	j	80000628 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e4:	f8843783          	ld	a5,-120(s0)
    800006e8:	00878713          	addi	a4,a5,8
    800006ec:	f8e43423          	sd	a4,-120(s0)
    800006f0:	0007b903          	ld	s2,0(a5)
    800006f4:	00090e63          	beqz	s2,80000710 <printf+0x182>
      for(; *s; s++)
    800006f8:	00094503          	lbu	a0,0(s2)
    800006fc:	d515                	beqz	a0,80000628 <printf+0x9a>
        consputc(*s);
    800006fe:	00000097          	auipc	ra,0x0
    80000702:	b84080e7          	jalr	-1148(ra) # 80000282 <consputc>
      for(; *s; s++)
    80000706:	0905                	addi	s2,s2,1
    80000708:	00094503          	lbu	a0,0(s2)
    8000070c:	f96d                	bnez	a0,800006fe <printf+0x170>
    8000070e:	bf29                	j	80000628 <printf+0x9a>
        s = "(null)";
    80000710:	00008917          	auipc	s2,0x8
    80000714:	91090913          	addi	s2,s2,-1776 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000718:	02800513          	li	a0,40
    8000071c:	b7cd                	j	800006fe <printf+0x170>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b62080e7          	jalr	-1182(ra) # 80000282 <consputc>
      break;
    80000728:	b701                	j	80000628 <printf+0x9a>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b56080e7          	jalr	-1194(ra) # 80000282 <consputc>
      consputc(c);
    80000734:	854a                	mv	a0,s2
    80000736:	00000097          	auipc	ra,0x0
    8000073a:	b4c080e7          	jalr	-1204(ra) # 80000282 <consputc>
      break;
    8000073e:	b5ed                	j	80000628 <printf+0x9a>
  if(locking)
    80000740:	020d9163          	bnez	s11,80000762 <printf+0x1d4>
}
    80000744:	70e6                	ld	ra,120(sp)
    80000746:	7446                	ld	s0,112(sp)
    80000748:	74a6                	ld	s1,104(sp)
    8000074a:	7906                	ld	s2,96(sp)
    8000074c:	69e6                	ld	s3,88(sp)
    8000074e:	6a46                	ld	s4,80(sp)
    80000750:	6aa6                	ld	s5,72(sp)
    80000752:	6b06                	ld	s6,64(sp)
    80000754:	7be2                	ld	s7,56(sp)
    80000756:	7c42                	ld	s8,48(sp)
    80000758:	7ca2                	ld	s9,40(sp)
    8000075a:	7d02                	ld	s10,32(sp)
    8000075c:	6de2                	ld	s11,24(sp)
    8000075e:	6129                	addi	sp,sp,192
    80000760:	8082                	ret
    release(&pr.lock);
    80000762:	00010517          	auipc	a0,0x10
    80000766:	62650513          	addi	a0,a0,1574 # 80010d88 <pr>
    8000076a:	00000097          	auipc	ra,0x0
    8000076e:	534080e7          	jalr	1332(ra) # 80000c9e <release>
}
    80000772:	bfc9                	j	80000744 <printf+0x1b6>

0000000080000774 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000774:	1101                	addi	sp,sp,-32
    80000776:	ec06                	sd	ra,24(sp)
    80000778:	e822                	sd	s0,16(sp)
    8000077a:	e426                	sd	s1,8(sp)
    8000077c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000077e:	00010497          	auipc	s1,0x10
    80000782:	60a48493          	addi	s1,s1,1546 # 80010d88 <pr>
    80000786:	00008597          	auipc	a1,0x8
    8000078a:	8b258593          	addi	a1,a1,-1870 # 80008038 <etext+0x38>
    8000078e:	8526                	mv	a0,s1
    80000790:	00000097          	auipc	ra,0x0
    80000794:	3ca080e7          	jalr	970(ra) # 80000b5a <initlock>
  pr.locking = 1;
    80000798:	4785                	li	a5,1
    8000079a:	cc9c                	sw	a5,24(s1)
}
    8000079c:	60e2                	ld	ra,24(sp)
    8000079e:	6442                	ld	s0,16(sp)
    800007a0:	64a2                	ld	s1,8(sp)
    800007a2:	6105                	addi	sp,sp,32
    800007a4:	8082                	ret

00000000800007a6 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a6:	1141                	addi	sp,sp,-16
    800007a8:	e406                	sd	ra,8(sp)
    800007aa:	e022                	sd	s0,0(sp)
    800007ac:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ae:	100007b7          	lui	a5,0x10000
    800007b2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b6:	f8000713          	li	a4,-128
    800007ba:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007be:	470d                	li	a4,3
    800007c0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007cc:	469d                	li	a3,7
    800007ce:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d6:	00008597          	auipc	a1,0x8
    800007da:	88258593          	addi	a1,a1,-1918 # 80008058 <digits+0x18>
    800007de:	00010517          	auipc	a0,0x10
    800007e2:	5ca50513          	addi	a0,a0,1482 # 80010da8 <uart_tx_lock>
    800007e6:	00000097          	auipc	ra,0x0
    800007ea:	374080e7          	jalr	884(ra) # 80000b5a <initlock>
}
    800007ee:	60a2                	ld	ra,8(sp)
    800007f0:	6402                	ld	s0,0(sp)
    800007f2:	0141                	addi	sp,sp,16
    800007f4:	8082                	ret

00000000800007f6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f6:	1101                	addi	sp,sp,-32
    800007f8:	ec06                	sd	ra,24(sp)
    800007fa:	e822                	sd	s0,16(sp)
    800007fc:	e426                	sd	s1,8(sp)
    800007fe:	1000                	addi	s0,sp,32
    80000800:	84aa                	mv	s1,a0
  push_off();
    80000802:	00000097          	auipc	ra,0x0
    80000806:	39c080e7          	jalr	924(ra) # 80000b9e <push_off>

  if(panicked){
    8000080a:	00008797          	auipc	a5,0x8
    8000080e:	3567a783          	lw	a5,854(a5) # 80008b60 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	10000737          	lui	a4,0x10000
  if(panicked){
    80000816:	c391                	beqz	a5,8000081a <uartputc_sync+0x24>
    for(;;)
    80000818:	a001                	j	80000818 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000081e:	0ff7f793          	andi	a5,a5,255
    80000822:	0207f793          	andi	a5,a5,32
    80000826:	dbf5                	beqz	a5,8000081a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000828:	0ff4f793          	andi	a5,s1,255
    8000082c:	10000737          	lui	a4,0x10000
    80000830:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000834:	00000097          	auipc	ra,0x0
    80000838:	40a080e7          	jalr	1034(ra) # 80000c3e <pop_off>
}
    8000083c:	60e2                	ld	ra,24(sp)
    8000083e:	6442                	ld	s0,16(sp)
    80000840:	64a2                	ld	s1,8(sp)
    80000842:	6105                	addi	sp,sp,32
    80000844:	8082                	ret

0000000080000846 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000846:	00008717          	auipc	a4,0x8
    8000084a:	32273703          	ld	a4,802(a4) # 80008b68 <uart_tx_r>
    8000084e:	00008797          	auipc	a5,0x8
    80000852:	3227b783          	ld	a5,802(a5) # 80008b70 <uart_tx_w>
    80000856:	06e78c63          	beq	a5,a4,800008ce <uartstart+0x88>
{
    8000085a:	7139                	addi	sp,sp,-64
    8000085c:	fc06                	sd	ra,56(sp)
    8000085e:	f822                	sd	s0,48(sp)
    80000860:	f426                	sd	s1,40(sp)
    80000862:	f04a                	sd	s2,32(sp)
    80000864:	ec4e                	sd	s3,24(sp)
    80000866:	e852                	sd	s4,16(sp)
    80000868:	e456                	sd	s5,8(sp)
    8000086a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000086c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000870:	00010a17          	auipc	s4,0x10
    80000874:	538a0a13          	addi	s4,s4,1336 # 80010da8 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	2f048493          	addi	s1,s1,752 # 80008b68 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	2f098993          	addi	s3,s3,752 # 80008b70 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000888:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000088c:	0ff7f793          	andi	a5,a5,255
    80000890:	0207f793          	andi	a5,a5,32
    80000894:	c785                	beqz	a5,800008bc <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000896:	01f77793          	andi	a5,a4,31
    8000089a:	97d2                	add	a5,a5,s4
    8000089c:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    800008a0:	0705                	addi	a4,a4,1
    800008a2:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a4:	8526                	mv	a0,s1
    800008a6:	00002097          	auipc	ra,0x2
    800008aa:	c90080e7          	jalr	-880(ra) # 80002536 <wakeup>
    
    WriteReg(THR, c);
    800008ae:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008b2:	6098                	ld	a4,0(s1)
    800008b4:	0009b783          	ld	a5,0(s3)
    800008b8:	fce798e3          	bne	a5,a4,80000888 <uartstart+0x42>
  }
}
    800008bc:	70e2                	ld	ra,56(sp)
    800008be:	7442                	ld	s0,48(sp)
    800008c0:	74a2                	ld	s1,40(sp)
    800008c2:	7902                	ld	s2,32(sp)
    800008c4:	69e2                	ld	s3,24(sp)
    800008c6:	6a42                	ld	s4,16(sp)
    800008c8:	6aa2                	ld	s5,8(sp)
    800008ca:	6121                	addi	sp,sp,64
    800008cc:	8082                	ret
    800008ce:	8082                	ret

00000000800008d0 <uartputc>:
{
    800008d0:	7179                	addi	sp,sp,-48
    800008d2:	f406                	sd	ra,40(sp)
    800008d4:	f022                	sd	s0,32(sp)
    800008d6:	ec26                	sd	s1,24(sp)
    800008d8:	e84a                	sd	s2,16(sp)
    800008da:	e44e                	sd	s3,8(sp)
    800008dc:	e052                	sd	s4,0(sp)
    800008de:	1800                	addi	s0,sp,48
    800008e0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008e2:	00010517          	auipc	a0,0x10
    800008e6:	4c650513          	addi	a0,a0,1222 # 80010da8 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	300080e7          	jalr	768(ra) # 80000bea <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	26e7a783          	lw	a5,622(a5) # 80008b60 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008797          	auipc	a5,0x8
    80000900:	2747b783          	ld	a5,628(a5) # 80008b70 <uart_tx_w>
    80000904:	00008717          	auipc	a4,0x8
    80000908:	26473703          	ld	a4,612(a4) # 80008b68 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010a17          	auipc	s4,0x10
    80000914:	498a0a13          	addi	s4,s4,1176 # 80010da8 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	25048493          	addi	s1,s1,592 # 80008b68 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	25090913          	addi	s2,s2,592 # 80008b70 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00002097          	auipc	ra,0x2
    80000934:	a56080e7          	jalr	-1450(ra) # 80002386 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	46248493          	addi	s1,s1,1122 # 80010da8 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00008717          	auipc	a4,0x8
    8000095e:	20f73b23          	sd	a5,534(a4) # 80008b70 <uart_tx_w>
  uartstart();
    80000962:	00000097          	auipc	ra,0x0
    80000966:	ee4080e7          	jalr	-284(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    8000096a:	8526                	mv	a0,s1
    8000096c:	00000097          	auipc	ra,0x0
    80000970:	332080e7          	jalr	818(ra) # 80000c9e <release>
}
    80000974:	70a2                	ld	ra,40(sp)
    80000976:	7402                	ld	s0,32(sp)
    80000978:	64e2                	ld	s1,24(sp)
    8000097a:	6942                	ld	s2,16(sp)
    8000097c:	69a2                	ld	s3,8(sp)
    8000097e:	6a02                	ld	s4,0(sp)
    80000980:	6145                	addi	sp,sp,48
    80000982:	8082                	ret
    for(;;)
    80000984:	a001                	j	80000984 <uartputc+0xb4>

0000000080000986 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000986:	1141                	addi	sp,sp,-16
    80000988:	e422                	sd	s0,8(sp)
    8000098a:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000098c:	100007b7          	lui	a5,0x10000
    80000990:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000994:	8b85                	andi	a5,a5,1
    80000996:	cb91                	beqz	a5,800009aa <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000998:	100007b7          	lui	a5,0x10000
    8000099c:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009a0:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009a4:	6422                	ld	s0,8(sp)
    800009a6:	0141                	addi	sp,sp,16
    800009a8:	8082                	ret
    return -1;
    800009aa:	557d                	li	a0,-1
    800009ac:	bfe5                	j	800009a4 <uartgetc+0x1e>

00000000800009ae <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009ae:	1101                	addi	sp,sp,-32
    800009b0:	ec06                	sd	ra,24(sp)
    800009b2:	e822                	sd	s0,16(sp)
    800009b4:	e426                	sd	s1,8(sp)
    800009b6:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b8:	54fd                	li	s1,-1
    int c = uartgetc();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	fcc080e7          	jalr	-52(ra) # 80000986 <uartgetc>
    if(c == -1)
    800009c2:	00950763          	beq	a0,s1,800009d0 <uartintr+0x22>
      break;
    consoleintr(c);
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	8fe080e7          	jalr	-1794(ra) # 800002c4 <consoleintr>
  while(1){
    800009ce:	b7f5                	j	800009ba <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009d0:	00010497          	auipc	s1,0x10
    800009d4:	3d848493          	addi	s1,s1,984 # 80010da8 <uart_tx_lock>
    800009d8:	8526                	mv	a0,s1
    800009da:	00000097          	auipc	ra,0x0
    800009de:	210080e7          	jalr	528(ra) # 80000bea <acquire>
  uartstart();
    800009e2:	00000097          	auipc	ra,0x0
    800009e6:	e64080e7          	jalr	-412(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    800009ea:	8526                	mv	a0,s1
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	2b2080e7          	jalr	690(ra) # 80000c9e <release>
}
    800009f4:	60e2                	ld	ra,24(sp)
    800009f6:	6442                	ld	s0,16(sp)
    800009f8:	64a2                	ld	s1,8(sp)
    800009fa:	6105                	addi	sp,sp,32
    800009fc:	8082                	ret

00000000800009fe <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009fe:	1101                	addi	sp,sp,-32
    80000a00:	ec06                	sd	ra,24(sp)
    80000a02:	e822                	sd	s0,16(sp)
    80000a04:	e426                	sd	s1,8(sp)
    80000a06:	e04a                	sd	s2,0(sp)
    80000a08:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a0a:	03451793          	slli	a5,a0,0x34
    80000a0e:	ebb9                	bnez	a5,80000a64 <kfree+0x66>
    80000a10:	84aa                	mv	s1,a0
    80000a12:	00022797          	auipc	a5,0x22
    80000a16:	5fe78793          	addi	a5,a5,1534 # 80023010 <end>
    80000a1a:	04f56563          	bltu	a0,a5,80000a64 <kfree+0x66>
    80000a1e:	47c5                	li	a5,17
    80000a20:	07ee                	slli	a5,a5,0x1b
    80000a22:	04f57163          	bgeu	a0,a5,80000a64 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a26:	6605                	lui	a2,0x1
    80000a28:	4585                	li	a1,1
    80000a2a:	00000097          	auipc	ra,0x0
    80000a2e:	2bc080e7          	jalr	700(ra) # 80000ce6 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a32:	00010917          	auipc	s2,0x10
    80000a36:	3ae90913          	addi	s2,s2,942 # 80010de0 <kmem>
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	1ae080e7          	jalr	430(ra) # 80000bea <acquire>
  r->next = kmem.freelist;
    80000a44:	01893783          	ld	a5,24(s2)
    80000a48:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a4a:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	24e080e7          	jalr	590(ra) # 80000c9e <release>
}
    80000a58:	60e2                	ld	ra,24(sp)
    80000a5a:	6442                	ld	s0,16(sp)
    80000a5c:	64a2                	ld	s1,8(sp)
    80000a5e:	6902                	ld	s2,0(sp)
    80000a60:	6105                	addi	sp,sp,32
    80000a62:	8082                	ret
    panic("kfree");
    80000a64:	00007517          	auipc	a0,0x7
    80000a68:	5fc50513          	addi	a0,a0,1532 # 80008060 <digits+0x20>
    80000a6c:	00000097          	auipc	ra,0x0
    80000a70:	ad8080e7          	jalr	-1320(ra) # 80000544 <panic>

0000000080000a74 <freerange>:
{
    80000a74:	7179                	addi	sp,sp,-48
    80000a76:	f406                	sd	ra,40(sp)
    80000a78:	f022                	sd	s0,32(sp)
    80000a7a:	ec26                	sd	s1,24(sp)
    80000a7c:	e84a                	sd	s2,16(sp)
    80000a7e:	e44e                	sd	s3,8(sp)
    80000a80:	e052                	sd	s4,0(sp)
    80000a82:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a84:	6785                	lui	a5,0x1
    80000a86:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a8a:	94aa                	add	s1,s1,a0
    80000a8c:	757d                	lui	a0,0xfffff
    80000a8e:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a90:	94be                	add	s1,s1,a5
    80000a92:	0095ee63          	bltu	a1,s1,80000aae <freerange+0x3a>
    80000a96:	892e                	mv	s2,a1
    kfree(p);
    80000a98:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a9a:	6985                	lui	s3,0x1
    kfree(p);
    80000a9c:	01448533          	add	a0,s1,s4
    80000aa0:	00000097          	auipc	ra,0x0
    80000aa4:	f5e080e7          	jalr	-162(ra) # 800009fe <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa8:	94ce                	add	s1,s1,s3
    80000aaa:	fe9979e3          	bgeu	s2,s1,80000a9c <freerange+0x28>
}
    80000aae:	70a2                	ld	ra,40(sp)
    80000ab0:	7402                	ld	s0,32(sp)
    80000ab2:	64e2                	ld	s1,24(sp)
    80000ab4:	6942                	ld	s2,16(sp)
    80000ab6:	69a2                	ld	s3,8(sp)
    80000ab8:	6a02                	ld	s4,0(sp)
    80000aba:	6145                	addi	sp,sp,48
    80000abc:	8082                	ret

0000000080000abe <kinit>:
{
    80000abe:	1141                	addi	sp,sp,-16
    80000ac0:	e406                	sd	ra,8(sp)
    80000ac2:	e022                	sd	s0,0(sp)
    80000ac4:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac6:	00007597          	auipc	a1,0x7
    80000aca:	5a258593          	addi	a1,a1,1442 # 80008068 <digits+0x28>
    80000ace:	00010517          	auipc	a0,0x10
    80000ad2:	31250513          	addi	a0,a0,786 # 80010de0 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	084080e7          	jalr	132(ra) # 80000b5a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	00022517          	auipc	a0,0x22
    80000ae6:	52e50513          	addi	a0,a0,1326 # 80023010 <end>
    80000aea:	00000097          	auipc	ra,0x0
    80000aee:	f8a080e7          	jalr	-118(ra) # 80000a74 <freerange>
}
    80000af2:	60a2                	ld	ra,8(sp)
    80000af4:	6402                	ld	s0,0(sp)
    80000af6:	0141                	addi	sp,sp,16
    80000af8:	8082                	ret

0000000080000afa <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000afa:	1101                	addi	sp,sp,-32
    80000afc:	ec06                	sd	ra,24(sp)
    80000afe:	e822                	sd	s0,16(sp)
    80000b00:	e426                	sd	s1,8(sp)
    80000b02:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b04:	00010497          	auipc	s1,0x10
    80000b08:	2dc48493          	addi	s1,s1,732 # 80010de0 <kmem>
    80000b0c:	8526                	mv	a0,s1
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	0dc080e7          	jalr	220(ra) # 80000bea <acquire>
  r = kmem.freelist;
    80000b16:	6c84                	ld	s1,24(s1)
  if(r)
    80000b18:	c885                	beqz	s1,80000b48 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b1a:	609c                	ld	a5,0(s1)
    80000b1c:	00010517          	auipc	a0,0x10
    80000b20:	2c450513          	addi	a0,a0,708 # 80010de0 <kmem>
    80000b24:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b26:	00000097          	auipc	ra,0x0
    80000b2a:	178080e7          	jalr	376(ra) # 80000c9e <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b2e:	6605                	lui	a2,0x1
    80000b30:	4595                	li	a1,5
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	1b2080e7          	jalr	434(ra) # 80000ce6 <memset>
  return (void*)r;
}
    80000b3c:	8526                	mv	a0,s1
    80000b3e:	60e2                	ld	ra,24(sp)
    80000b40:	6442                	ld	s0,16(sp)
    80000b42:	64a2                	ld	s1,8(sp)
    80000b44:	6105                	addi	sp,sp,32
    80000b46:	8082                	ret
  release(&kmem.lock);
    80000b48:	00010517          	auipc	a0,0x10
    80000b4c:	29850513          	addi	a0,a0,664 # 80010de0 <kmem>
    80000b50:	00000097          	auipc	ra,0x0
    80000b54:	14e080e7          	jalr	334(ra) # 80000c9e <release>
  if(r)
    80000b58:	b7d5                	j	80000b3c <kalloc+0x42>

0000000080000b5a <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b5a:	1141                	addi	sp,sp,-16
    80000b5c:	e422                	sd	s0,8(sp)
    80000b5e:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b60:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b62:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b66:	00053823          	sd	zero,16(a0)
}
    80000b6a:	6422                	ld	s0,8(sp)
    80000b6c:	0141                	addi	sp,sp,16
    80000b6e:	8082                	ret

0000000080000b70 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b70:	411c                	lw	a5,0(a0)
    80000b72:	e399                	bnez	a5,80000b78 <holding+0x8>
    80000b74:	4501                	li	a0,0
  return r;
}
    80000b76:	8082                	ret
{
    80000b78:	1101                	addi	sp,sp,-32
    80000b7a:	ec06                	sd	ra,24(sp)
    80000b7c:	e822                	sd	s0,16(sp)
    80000b7e:	e426                	sd	s1,8(sp)
    80000b80:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b82:	6904                	ld	s1,16(a0)
    80000b84:	00001097          	auipc	ra,0x1
    80000b88:	e26080e7          	jalr	-474(ra) # 800019aa <mycpu>
    80000b8c:	40a48533          	sub	a0,s1,a0
    80000b90:	00153513          	seqz	a0,a0
}
    80000b94:	60e2                	ld	ra,24(sp)
    80000b96:	6442                	ld	s0,16(sp)
    80000b98:	64a2                	ld	s1,8(sp)
    80000b9a:	6105                	addi	sp,sp,32
    80000b9c:	8082                	ret

0000000080000b9e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus"
    80000ba8:	100024f3          	csrr	s1,sstatus
    80000bac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bb0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0"
    80000bb2:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb6:	00001097          	auipc	ra,0x1
    80000bba:	df4080e7          	jalr	-524(ra) # 800019aa <mycpu>
    80000bbe:	5d3c                	lw	a5,120(a0)
    80000bc0:	cf89                	beqz	a5,80000bda <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bc2:	00001097          	auipc	ra,0x1
    80000bc6:	de8080e7          	jalr	-536(ra) # 800019aa <mycpu>
    80000bca:	5d3c                	lw	a5,120(a0)
    80000bcc:	2785                	addiw	a5,a5,1
    80000bce:	dd3c                	sw	a5,120(a0)
}
    80000bd0:	60e2                	ld	ra,24(sp)
    80000bd2:	6442                	ld	s0,16(sp)
    80000bd4:	64a2                	ld	s1,8(sp)
    80000bd6:	6105                	addi	sp,sp,32
    80000bd8:	8082                	ret
    mycpu()->intena = old;
    80000bda:	00001097          	auipc	ra,0x1
    80000bde:	dd0080e7          	jalr	-560(ra) # 800019aa <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000be2:	8085                	srli	s1,s1,0x1
    80000be4:	8885                	andi	s1,s1,1
    80000be6:	dd64                	sw	s1,124(a0)
    80000be8:	bfe9                	j	80000bc2 <push_off+0x24>

0000000080000bea <acquire>:
{
    80000bea:	1101                	addi	sp,sp,-32
    80000bec:	ec06                	sd	ra,24(sp)
    80000bee:	e822                	sd	s0,16(sp)
    80000bf0:	e426                	sd	s1,8(sp)
    80000bf2:	1000                	addi	s0,sp,32
    80000bf4:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf6:	00000097          	auipc	ra,0x0
    80000bfa:	fa8080e7          	jalr	-88(ra) # 80000b9e <push_off>
  if(holding(lk))
    80000bfe:	8526                	mv	a0,s1
    80000c00:	00000097          	auipc	ra,0x0
    80000c04:	f70080e7          	jalr	-144(ra) # 80000b70 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c08:	4705                	li	a4,1
  if(holding(lk))
    80000c0a:	e115                	bnez	a0,80000c2e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c0c:	87ba                	mv	a5,a4
    80000c0e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c12:	2781                	sext.w	a5,a5
    80000c14:	ffe5                	bnez	a5,80000c0c <acquire+0x22>
  __sync_synchronize();
    80000c16:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c1a:	00001097          	auipc	ra,0x1
    80000c1e:	d90080e7          	jalr	-624(ra) # 800019aa <mycpu>
    80000c22:	e888                	sd	a0,16(s1)
}
    80000c24:	60e2                	ld	ra,24(sp)
    80000c26:	6442                	ld	s0,16(sp)
    80000c28:	64a2                	ld	s1,8(sp)
    80000c2a:	6105                	addi	sp,sp,32
    80000c2c:	8082                	ret
    panic("acquire");
    80000c2e:	00007517          	auipc	a0,0x7
    80000c32:	44250513          	addi	a0,a0,1090 # 80008070 <digits+0x30>
    80000c36:	00000097          	auipc	ra,0x0
    80000c3a:	90e080e7          	jalr	-1778(ra) # 80000544 <panic>

0000000080000c3e <pop_off>:

void
pop_off(void)
{
    80000c3e:	1141                	addi	sp,sp,-16
    80000c40:	e406                	sd	ra,8(sp)
    80000c42:	e022                	sd	s0,0(sp)
    80000c44:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c46:	00001097          	auipc	ra,0x1
    80000c4a:	d64080e7          	jalr	-668(ra) # 800019aa <mycpu>
  asm volatile("csrr %0, sstatus"
    80000c4e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c52:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c54:	e78d                	bnez	a5,80000c7e <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c56:	5d3c                	lw	a5,120(a0)
    80000c58:	02f05b63          	blez	a5,80000c8e <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c5c:	37fd                	addiw	a5,a5,-1
    80000c5e:	0007871b          	sext.w	a4,a5
    80000c62:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c64:	eb09                	bnez	a4,80000c76 <pop_off+0x38>
    80000c66:	5d7c                	lw	a5,124(a0)
    80000c68:	c799                	beqz	a5,80000c76 <pop_off+0x38>
  asm volatile("csrr %0, sstatus"
    80000c6a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c6e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0"
    80000c72:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c76:	60a2                	ld	ra,8(sp)
    80000c78:	6402                	ld	s0,0(sp)
    80000c7a:	0141                	addi	sp,sp,16
    80000c7c:	8082                	ret
    panic("pop_off - interruptible");
    80000c7e:	00007517          	auipc	a0,0x7
    80000c82:	3fa50513          	addi	a0,a0,1018 # 80008078 <digits+0x38>
    80000c86:	00000097          	auipc	ra,0x0
    80000c8a:	8be080e7          	jalr	-1858(ra) # 80000544 <panic>
    panic("pop_off");
    80000c8e:	00007517          	auipc	a0,0x7
    80000c92:	40250513          	addi	a0,a0,1026 # 80008090 <digits+0x50>
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	8ae080e7          	jalr	-1874(ra) # 80000544 <panic>

0000000080000c9e <release>:
{
    80000c9e:	1101                	addi	sp,sp,-32
    80000ca0:	ec06                	sd	ra,24(sp)
    80000ca2:	e822                	sd	s0,16(sp)
    80000ca4:	e426                	sd	s1,8(sp)
    80000ca6:	1000                	addi	s0,sp,32
    80000ca8:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	ec6080e7          	jalr	-314(ra) # 80000b70 <holding>
    80000cb2:	c115                	beqz	a0,80000cd6 <release+0x38>
  lk->cpu = 0;
    80000cb4:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb8:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cbc:	0f50000f          	fence	iorw,ow
    80000cc0:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	f7a080e7          	jalr	-134(ra) # 80000c3e <pop_off>
}
    80000ccc:	60e2                	ld	ra,24(sp)
    80000cce:	6442                	ld	s0,16(sp)
    80000cd0:	64a2                	ld	s1,8(sp)
    80000cd2:	6105                	addi	sp,sp,32
    80000cd4:	8082                	ret
    panic("release");
    80000cd6:	00007517          	auipc	a0,0x7
    80000cda:	3c250513          	addi	a0,a0,962 # 80008098 <digits+0x58>
    80000cde:	00000097          	auipc	ra,0x0
    80000ce2:	866080e7          	jalr	-1946(ra) # 80000544 <panic>

0000000080000ce6 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce6:	1141                	addi	sp,sp,-16
    80000ce8:	e422                	sd	s0,8(sp)
    80000cea:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cec:	ce09                	beqz	a2,80000d06 <memset+0x20>
    80000cee:	87aa                	mv	a5,a0
    80000cf0:	fff6071b          	addiw	a4,a2,-1
    80000cf4:	1702                	slli	a4,a4,0x20
    80000cf6:	9301                	srli	a4,a4,0x20
    80000cf8:	0705                	addi	a4,a4,1
    80000cfa:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cfc:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d00:	0785                	addi	a5,a5,1
    80000d02:	fee79de3          	bne	a5,a4,80000cfc <memset+0x16>
  }
  return dst;
}
    80000d06:	6422                	ld	s0,8(sp)
    80000d08:	0141                	addi	sp,sp,16
    80000d0a:	8082                	ret

0000000080000d0c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d12:	ca05                	beqz	a2,80000d42 <memcmp+0x36>
    80000d14:	fff6069b          	addiw	a3,a2,-1
    80000d18:	1682                	slli	a3,a3,0x20
    80000d1a:	9281                	srli	a3,a3,0x20
    80000d1c:	0685                	addi	a3,a3,1
    80000d1e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d20:	00054783          	lbu	a5,0(a0)
    80000d24:	0005c703          	lbu	a4,0(a1)
    80000d28:	00e79863          	bne	a5,a4,80000d38 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d2c:	0505                	addi	a0,a0,1
    80000d2e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d30:	fed518e3          	bne	a0,a3,80000d20 <memcmp+0x14>
  }

  return 0;
    80000d34:	4501                	li	a0,0
    80000d36:	a019                	j	80000d3c <memcmp+0x30>
      return *s1 - *s2;
    80000d38:	40e7853b          	subw	a0,a5,a4
}
    80000d3c:	6422                	ld	s0,8(sp)
    80000d3e:	0141                	addi	sp,sp,16
    80000d40:	8082                	ret
  return 0;
    80000d42:	4501                	li	a0,0
    80000d44:	bfe5                	j	80000d3c <memcmp+0x30>

0000000080000d46 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d46:	1141                	addi	sp,sp,-16
    80000d48:	e422                	sd	s0,8(sp)
    80000d4a:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d4c:	ca0d                	beqz	a2,80000d7e <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d4e:	00a5f963          	bgeu	a1,a0,80000d60 <memmove+0x1a>
    80000d52:	02061693          	slli	a3,a2,0x20
    80000d56:	9281                	srli	a3,a3,0x20
    80000d58:	00d58733          	add	a4,a1,a3
    80000d5c:	02e56463          	bltu	a0,a4,80000d84 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d60:	fff6079b          	addiw	a5,a2,-1
    80000d64:	1782                	slli	a5,a5,0x20
    80000d66:	9381                	srli	a5,a5,0x20
    80000d68:	0785                	addi	a5,a5,1
    80000d6a:	97ae                	add	a5,a5,a1
    80000d6c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d6e:	0585                	addi	a1,a1,1
    80000d70:	0705                	addi	a4,a4,1
    80000d72:	fff5c683          	lbu	a3,-1(a1)
    80000d76:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d7a:	fef59ae3          	bne	a1,a5,80000d6e <memmove+0x28>

  return dst;
}
    80000d7e:	6422                	ld	s0,8(sp)
    80000d80:	0141                	addi	sp,sp,16
    80000d82:	8082                	ret
    d += n;
    80000d84:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d86:	fff6079b          	addiw	a5,a2,-1
    80000d8a:	1782                	slli	a5,a5,0x20
    80000d8c:	9381                	srli	a5,a5,0x20
    80000d8e:	fff7c793          	not	a5,a5
    80000d92:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d94:	177d                	addi	a4,a4,-1
    80000d96:	16fd                	addi	a3,a3,-1
    80000d98:	00074603          	lbu	a2,0(a4)
    80000d9c:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000da0:	fef71ae3          	bne	a4,a5,80000d94 <memmove+0x4e>
    80000da4:	bfe9                	j	80000d7e <memmove+0x38>

0000000080000da6 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da6:	1141                	addi	sp,sp,-16
    80000da8:	e406                	sd	ra,8(sp)
    80000daa:	e022                	sd	s0,0(sp)
    80000dac:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dae:	00000097          	auipc	ra,0x0
    80000db2:	f98080e7          	jalr	-104(ra) # 80000d46 <memmove>
}
    80000db6:	60a2                	ld	ra,8(sp)
    80000db8:	6402                	ld	s0,0(sp)
    80000dba:	0141                	addi	sp,sp,16
    80000dbc:	8082                	ret

0000000080000dbe <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dbe:	1141                	addi	sp,sp,-16
    80000dc0:	e422                	sd	s0,8(sp)
    80000dc2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dc4:	ce11                	beqz	a2,80000de0 <strncmp+0x22>
    80000dc6:	00054783          	lbu	a5,0(a0)
    80000dca:	cf89                	beqz	a5,80000de4 <strncmp+0x26>
    80000dcc:	0005c703          	lbu	a4,0(a1)
    80000dd0:	00f71a63          	bne	a4,a5,80000de4 <strncmp+0x26>
    n--, p++, q++;
    80000dd4:	367d                	addiw	a2,a2,-1
    80000dd6:	0505                	addi	a0,a0,1
    80000dd8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dda:	f675                	bnez	a2,80000dc6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ddc:	4501                	li	a0,0
    80000dde:	a809                	j	80000df0 <strncmp+0x32>
    80000de0:	4501                	li	a0,0
    80000de2:	a039                	j	80000df0 <strncmp+0x32>
  if(n == 0)
    80000de4:	ca09                	beqz	a2,80000df6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de6:	00054503          	lbu	a0,0(a0)
    80000dea:	0005c783          	lbu	a5,0(a1)
    80000dee:	9d1d                	subw	a0,a0,a5
}
    80000df0:	6422                	ld	s0,8(sp)
    80000df2:	0141                	addi	sp,sp,16
    80000df4:	8082                	ret
    return 0;
    80000df6:	4501                	li	a0,0
    80000df8:	bfe5                	j	80000df0 <strncmp+0x32>

0000000080000dfa <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dfa:	1141                	addi	sp,sp,-16
    80000dfc:	e422                	sd	s0,8(sp)
    80000dfe:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e00:	872a                	mv	a4,a0
    80000e02:	8832                	mv	a6,a2
    80000e04:	367d                	addiw	a2,a2,-1
    80000e06:	01005963          	blez	a6,80000e18 <strncpy+0x1e>
    80000e0a:	0705                	addi	a4,a4,1
    80000e0c:	0005c783          	lbu	a5,0(a1)
    80000e10:	fef70fa3          	sb	a5,-1(a4)
    80000e14:	0585                	addi	a1,a1,1
    80000e16:	f7f5                	bnez	a5,80000e02 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e18:	00c05d63          	blez	a2,80000e32 <strncpy+0x38>
    80000e1c:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e1e:	0685                	addi	a3,a3,1
    80000e20:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e24:	fff6c793          	not	a5,a3
    80000e28:	9fb9                	addw	a5,a5,a4
    80000e2a:	010787bb          	addw	a5,a5,a6
    80000e2e:	fef048e3          	bgtz	a5,80000e1e <strncpy+0x24>
  return os;
}
    80000e32:	6422                	ld	s0,8(sp)
    80000e34:	0141                	addi	sp,sp,16
    80000e36:	8082                	ret

0000000080000e38 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e38:	1141                	addi	sp,sp,-16
    80000e3a:	e422                	sd	s0,8(sp)
    80000e3c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e3e:	02c05363          	blez	a2,80000e64 <safestrcpy+0x2c>
    80000e42:	fff6069b          	addiw	a3,a2,-1
    80000e46:	1682                	slli	a3,a3,0x20
    80000e48:	9281                	srli	a3,a3,0x20
    80000e4a:	96ae                	add	a3,a3,a1
    80000e4c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e4e:	00d58963          	beq	a1,a3,80000e60 <safestrcpy+0x28>
    80000e52:	0585                	addi	a1,a1,1
    80000e54:	0785                	addi	a5,a5,1
    80000e56:	fff5c703          	lbu	a4,-1(a1)
    80000e5a:	fee78fa3          	sb	a4,-1(a5)
    80000e5e:	fb65                	bnez	a4,80000e4e <safestrcpy+0x16>
    ;
  *s = 0;
    80000e60:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e64:	6422                	ld	s0,8(sp)
    80000e66:	0141                	addi	sp,sp,16
    80000e68:	8082                	ret

0000000080000e6a <strlen>:

int
strlen(const char *s)
{
    80000e6a:	1141                	addi	sp,sp,-16
    80000e6c:	e422                	sd	s0,8(sp)
    80000e6e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e70:	00054783          	lbu	a5,0(a0)
    80000e74:	cf91                	beqz	a5,80000e90 <strlen+0x26>
    80000e76:	0505                	addi	a0,a0,1
    80000e78:	87aa                	mv	a5,a0
    80000e7a:	4685                	li	a3,1
    80000e7c:	9e89                	subw	a3,a3,a0
    80000e7e:	00f6853b          	addw	a0,a3,a5
    80000e82:	0785                	addi	a5,a5,1
    80000e84:	fff7c703          	lbu	a4,-1(a5)
    80000e88:	fb7d                	bnez	a4,80000e7e <strlen+0x14>
    ;
  return n;
}
    80000e8a:	6422                	ld	s0,8(sp)
    80000e8c:	0141                	addi	sp,sp,16
    80000e8e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e90:	4501                	li	a0,0
    80000e92:	bfe5                	j	80000e8a <strlen+0x20>

0000000080000e94 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e406                	sd	ra,8(sp)
    80000e98:	e022                	sd	s0,0(sp)
    80000e9a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	afe080e7          	jalr	-1282(ra) # 8000199a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ea4:	00008717          	auipc	a4,0x8
    80000ea8:	cd470713          	addi	a4,a4,-812 # 80008b78 <started>
  if(cpuid() == 0){
    80000eac:	c139                	beqz	a0,80000ef2 <main+0x5e>
    while(started == 0)
    80000eae:	431c                	lw	a5,0(a4)
    80000eb0:	2781                	sext.w	a5,a5
    80000eb2:	dff5                	beqz	a5,80000eae <main+0x1a>
      ;
    __sync_synchronize();
    80000eb4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb8:	00001097          	auipc	ra,0x1
    80000ebc:	ae2080e7          	jalr	-1310(ra) # 8000199a <cpuid>
    80000ec0:	85aa                	mv	a1,a0
    80000ec2:	00007517          	auipc	a0,0x7
    80000ec6:	1f650513          	addi	a0,a0,502 # 800080b8 <digits+0x78>
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	6c4080e7          	jalr	1732(ra) # 8000058e <printf>
    kvminithart();    // turn on paging
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	0d8080e7          	jalr	216(ra) # 80000faa <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eda:	00002097          	auipc	ra,0x2
    80000ede:	bf8080e7          	jalr	-1032(ra) # 80002ad2 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00005097          	auipc	ra,0x5
    80000ee6:	48e080e7          	jalr	1166(ra) # 80006370 <plicinithart>
  }

  scheduler();        
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	14a080e7          	jalr	330(ra) # 80002034 <scheduler>
    consoleinit();
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	564080e7          	jalr	1380(ra) # 80000456 <consoleinit>
    printfinit();
    80000efa:	00000097          	auipc	ra,0x0
    80000efe:	87a080e7          	jalr	-1926(ra) # 80000774 <printfinit>
    printf("\n");
    80000f02:	00007517          	auipc	a0,0x7
    80000f06:	1c650513          	addi	a0,a0,454 # 800080c8 <digits+0x88>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	684080e7          	jalr	1668(ra) # 8000058e <printf>
    printf("xv6 kernel is booting\n");
    80000f12:	00007517          	auipc	a0,0x7
    80000f16:	18e50513          	addi	a0,a0,398 # 800080a0 <digits+0x60>
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	674080e7          	jalr	1652(ra) # 8000058e <printf>
    printf("\n");
    80000f22:	00007517          	auipc	a0,0x7
    80000f26:	1a650513          	addi	a0,a0,422 # 800080c8 <digits+0x88>
    80000f2a:	fffff097          	auipc	ra,0xfffff
    80000f2e:	664080e7          	jalr	1636(ra) # 8000058e <printf>
    kinit();         // physical page allocator
    80000f32:	00000097          	auipc	ra,0x0
    80000f36:	b8c080e7          	jalr	-1140(ra) # 80000abe <kinit>
    kvminit();       // create kernel page table
    80000f3a:	00000097          	auipc	ra,0x0
    80000f3e:	326080e7          	jalr	806(ra) # 80001260 <kvminit>
    kvminithart();   // turn on paging
    80000f42:	00000097          	auipc	ra,0x0
    80000f46:	068080e7          	jalr	104(ra) # 80000faa <kvminithart>
    procinit();      // process table
    80000f4a:	00001097          	auipc	ra,0x1
    80000f4e:	99c080e7          	jalr	-1636(ra) # 800018e6 <procinit>
    trapinit();      // trap vectors
    80000f52:	00002097          	auipc	ra,0x2
    80000f56:	b58080e7          	jalr	-1192(ra) # 80002aaa <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00002097          	auipc	ra,0x2
    80000f5e:	b78080e7          	jalr	-1160(ra) # 80002ad2 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	3f8080e7          	jalr	1016(ra) # 8000635a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	406080e7          	jalr	1030(ra) # 80006370 <plicinithart>
    binit();         // buffer cache
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	5ba080e7          	jalr	1466(ra) # 8000352c <binit>
    iinit();         // inode table
    80000f7a:	00003097          	auipc	ra,0x3
    80000f7e:	c5e080e7          	jalr	-930(ra) # 80003bd8 <iinit>
    fileinit();      // file table
    80000f82:	00004097          	auipc	ra,0x4
    80000f86:	bfc080e7          	jalr	-1028(ra) # 80004b7e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	4ee080e7          	jalr	1262(ra) # 80006478 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	d88080e7          	jalr	-632(ra) # 80001d1a <userinit>
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    started = 1;
    80000f9e:	4785                	li	a5,1
    80000fa0:	00008717          	auipc	a4,0x8
    80000fa4:	bcf72c23          	sw	a5,-1064(a4) # 80008b78 <started>
    80000fa8:	b789                	j	80000eea <main+0x56>

0000000080000faa <kvminithart>:
}

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void kvminithart()
{
    80000faa:	1141                	addi	sp,sp,-16
    80000fac:	e422                	sd	s0,8(sp)
    80000fae:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fb0:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb4:	00008797          	auipc	a5,0x8
    80000fb8:	bcc7b783          	ld	a5,-1076(a5) # 80008b80 <kernel_pagetable>
    80000fbc:	83b1                	srli	a5,a5,0xc
    80000fbe:	577d                	li	a4,-1
    80000fc0:	177e                	slli	a4,a4,0x3f
    80000fc2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0"
    80000fc4:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fc8:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fcc:	6422                	ld	s0,8(sp)
    80000fce:	0141                	addi	sp,sp,16
    80000fd0:	8082                	ret

0000000080000fd2 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd2:	7139                	addi	sp,sp,-64
    80000fd4:	fc06                	sd	ra,56(sp)
    80000fd6:	f822                	sd	s0,48(sp)
    80000fd8:	f426                	sd	s1,40(sp)
    80000fda:	f04a                	sd	s2,32(sp)
    80000fdc:	ec4e                	sd	s3,24(sp)
    80000fde:	e852                	sd	s4,16(sp)
    80000fe0:	e456                	sd	s5,8(sp)
    80000fe2:	e05a                	sd	s6,0(sp)
    80000fe4:	0080                	addi	s0,sp,64
    80000fe6:	84aa                	mv	s1,a0
    80000fe8:	89ae                	mv	s3,a1
    80000fea:	8ab2                	mv	s5,a2
  if (va >= MAXVA)
    80000fec:	57fd                	li	a5,-1
    80000fee:	83e9                	srli	a5,a5,0x1a
    80000ff0:	4a79                	li	s4,30
    panic("walk");

  for (int level = 2; level > 0; level--)
    80000ff2:	4b31                	li	s6,12
  if (va >= MAXVA)
    80000ff4:	04b7f263          	bgeu	a5,a1,80001038 <walk+0x66>
    panic("walk");
    80000ff8:	00007517          	auipc	a0,0x7
    80000ffc:	0d850513          	addi	a0,a0,216 # 800080d0 <digits+0x90>
    80001000:	fffff097          	auipc	ra,0xfffff
    80001004:	544080e7          	jalr	1348(ra) # 80000544 <panic>
    {
      pagetable = (pagetable_t)PTE2PA(*pte);
    }
    else
    {
      if (!alloc || (pagetable = (pde_t *)kalloc()) == 0)
    80001008:	060a8663          	beqz	s5,80001074 <walk+0xa2>
    8000100c:	00000097          	auipc	ra,0x0
    80001010:	aee080e7          	jalr	-1298(ra) # 80000afa <kalloc>
    80001014:	84aa                	mv	s1,a0
    80001016:	c529                	beqz	a0,80001060 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001018:	6605                	lui	a2,0x1
    8000101a:	4581                	li	a1,0
    8000101c:	00000097          	auipc	ra,0x0
    80001020:	cca080e7          	jalr	-822(ra) # 80000ce6 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001024:	00c4d793          	srli	a5,s1,0xc
    80001028:	07aa                	slli	a5,a5,0xa
    8000102a:	0017e793          	ori	a5,a5,1
    8000102e:	00f93023          	sd	a5,0(s2)
  for (int level = 2; level > 0; level--)
    80001032:	3a5d                	addiw	s4,s4,-9
    80001034:	036a0063          	beq	s4,s6,80001054 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001038:	0149d933          	srl	s2,s3,s4
    8000103c:	1ff97913          	andi	s2,s2,511
    80001040:	090e                	slli	s2,s2,0x3
    80001042:	9926                	add	s2,s2,s1
    if (*pte & PTE_V)
    80001044:	00093483          	ld	s1,0(s2)
    80001048:	0014f793          	andi	a5,s1,1
    8000104c:	dfd5                	beqz	a5,80001008 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000104e:	80a9                	srli	s1,s1,0xa
    80001050:	04b2                	slli	s1,s1,0xc
    80001052:	b7c5                	j	80001032 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001054:	00c9d513          	srli	a0,s3,0xc
    80001058:	1ff57513          	andi	a0,a0,511
    8000105c:	050e                	slli	a0,a0,0x3
    8000105e:	9526                	add	a0,a0,s1
}
    80001060:	70e2                	ld	ra,56(sp)
    80001062:	7442                	ld	s0,48(sp)
    80001064:	74a2                	ld	s1,40(sp)
    80001066:	7902                	ld	s2,32(sp)
    80001068:	69e2                	ld	s3,24(sp)
    8000106a:	6a42                	ld	s4,16(sp)
    8000106c:	6aa2                	ld	s5,8(sp)
    8000106e:	6b02                	ld	s6,0(sp)
    80001070:	6121                	addi	sp,sp,64
    80001072:	8082                	ret
        return 0;
    80001074:	4501                	li	a0,0
    80001076:	b7ed                	j	80001060 <walk+0x8e>

0000000080001078 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if (va >= MAXVA)
    80001078:	57fd                	li	a5,-1
    8000107a:	83e9                	srli	a5,a5,0x1a
    8000107c:	00b7f463          	bgeu	a5,a1,80001084 <walkaddr+0xc>
    return 0;
    80001080:	4501                	li	a0,0
    return 0;
  if ((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001082:	8082                	ret
{
    80001084:	1141                	addi	sp,sp,-16
    80001086:	e406                	sd	ra,8(sp)
    80001088:	e022                	sd	s0,0(sp)
    8000108a:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000108c:	4601                	li	a2,0
    8000108e:	00000097          	auipc	ra,0x0
    80001092:	f44080e7          	jalr	-188(ra) # 80000fd2 <walk>
  if (pte == 0)
    80001096:	c105                	beqz	a0,800010b6 <walkaddr+0x3e>
  if ((*pte & PTE_V) == 0)
    80001098:	611c                	ld	a5,0(a0)
  if ((*pte & PTE_U) == 0)
    8000109a:	0117f693          	andi	a3,a5,17
    8000109e:	4745                	li	a4,17
    return 0;
    800010a0:	4501                	li	a0,0
  if ((*pte & PTE_U) == 0)
    800010a2:	00e68663          	beq	a3,a4,800010ae <walkaddr+0x36>
}
    800010a6:	60a2                	ld	ra,8(sp)
    800010a8:	6402                	ld	s0,0(sp)
    800010aa:	0141                	addi	sp,sp,16
    800010ac:	8082                	ret
  pa = PTE2PA(*pte);
    800010ae:	00a7d513          	srli	a0,a5,0xa
    800010b2:	0532                	slli	a0,a0,0xc
  return pa;
    800010b4:	bfcd                	j	800010a6 <walkaddr+0x2e>
    return 0;
    800010b6:	4501                	li	a0,0
    800010b8:	b7fd                	j	800010a6 <walkaddr+0x2e>

00000000800010ba <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010ba:	715d                	addi	sp,sp,-80
    800010bc:	e486                	sd	ra,72(sp)
    800010be:	e0a2                	sd	s0,64(sp)
    800010c0:	fc26                	sd	s1,56(sp)
    800010c2:	f84a                	sd	s2,48(sp)
    800010c4:	f44e                	sd	s3,40(sp)
    800010c6:	f052                	sd	s4,32(sp)
    800010c8:	ec56                	sd	s5,24(sp)
    800010ca:	e85a                	sd	s6,16(sp)
    800010cc:	e45e                	sd	s7,8(sp)
    800010ce:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if (size == 0)
    800010d0:	c205                	beqz	a2,800010f0 <mappages+0x36>
    800010d2:	8aaa                	mv	s5,a0
    800010d4:	8b3a                	mv	s6,a4
    panic("mappages: size");

  a = PGROUNDDOWN(va);
    800010d6:	77fd                	lui	a5,0xfffff
    800010d8:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010dc:	15fd                	addi	a1,a1,-1
    800010de:	00c589b3          	add	s3,a1,a2
    800010e2:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010e6:	8952                	mv	s2,s4
    800010e8:	41468a33          	sub	s4,a3,s4
    if (*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if (a == last)
      break;
    a += PGSIZE;
    800010ec:	6b85                	lui	s7,0x1
    800010ee:	a015                	j	80001112 <mappages+0x58>
    panic("mappages: size");
    800010f0:	00007517          	auipc	a0,0x7
    800010f4:	fe850513          	addi	a0,a0,-24 # 800080d8 <digits+0x98>
    800010f8:	fffff097          	auipc	ra,0xfffff
    800010fc:	44c080e7          	jalr	1100(ra) # 80000544 <panic>
      panic("mappages: remap");
    80001100:	00007517          	auipc	a0,0x7
    80001104:	fe850513          	addi	a0,a0,-24 # 800080e8 <digits+0xa8>
    80001108:	fffff097          	auipc	ra,0xfffff
    8000110c:	43c080e7          	jalr	1084(ra) # 80000544 <panic>
    a += PGSIZE;
    80001110:	995e                	add	s2,s2,s7
  for (;;)
    80001112:	012a04b3          	add	s1,s4,s2
    if ((pte = walk(pagetable, a, 1)) == 0)
    80001116:	4605                	li	a2,1
    80001118:	85ca                	mv	a1,s2
    8000111a:	8556                	mv	a0,s5
    8000111c:	00000097          	auipc	ra,0x0
    80001120:	eb6080e7          	jalr	-330(ra) # 80000fd2 <walk>
    80001124:	cd19                	beqz	a0,80001142 <mappages+0x88>
    if (*pte & PTE_V)
    80001126:	611c                	ld	a5,0(a0)
    80001128:	8b85                	andi	a5,a5,1
    8000112a:	fbf9                	bnez	a5,80001100 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000112c:	80b1                	srli	s1,s1,0xc
    8000112e:	04aa                	slli	s1,s1,0xa
    80001130:	0164e4b3          	or	s1,s1,s6
    80001134:	0014e493          	ori	s1,s1,1
    80001138:	e104                	sd	s1,0(a0)
    if (a == last)
    8000113a:	fd391be3          	bne	s2,s3,80001110 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    8000113e:	4501                	li	a0,0
    80001140:	a011                	j	80001144 <mappages+0x8a>
      return -1;
    80001142:	557d                	li	a0,-1
}
    80001144:	60a6                	ld	ra,72(sp)
    80001146:	6406                	ld	s0,64(sp)
    80001148:	74e2                	ld	s1,56(sp)
    8000114a:	7942                	ld	s2,48(sp)
    8000114c:	79a2                	ld	s3,40(sp)
    8000114e:	7a02                	ld	s4,32(sp)
    80001150:	6ae2                	ld	s5,24(sp)
    80001152:	6b42                	ld	s6,16(sp)
    80001154:	6ba2                	ld	s7,8(sp)
    80001156:	6161                	addi	sp,sp,80
    80001158:	8082                	ret

000000008000115a <kvmmap>:
{
    8000115a:	1141                	addi	sp,sp,-16
    8000115c:	e406                	sd	ra,8(sp)
    8000115e:	e022                	sd	s0,0(sp)
    80001160:	0800                	addi	s0,sp,16
    80001162:	87b6                	mv	a5,a3
  if (mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001164:	86b2                	mv	a3,a2
    80001166:	863e                	mv	a2,a5
    80001168:	00000097          	auipc	ra,0x0
    8000116c:	f52080e7          	jalr	-174(ra) # 800010ba <mappages>
    80001170:	e509                	bnez	a0,8000117a <kvmmap+0x20>
}
    80001172:	60a2                	ld	ra,8(sp)
    80001174:	6402                	ld	s0,0(sp)
    80001176:	0141                	addi	sp,sp,16
    80001178:	8082                	ret
    panic("kvmmap");
    8000117a:	00007517          	auipc	a0,0x7
    8000117e:	f7e50513          	addi	a0,a0,-130 # 800080f8 <digits+0xb8>
    80001182:	fffff097          	auipc	ra,0xfffff
    80001186:	3c2080e7          	jalr	962(ra) # 80000544 <panic>

000000008000118a <kvmmake>:
{
    8000118a:	1101                	addi	sp,sp,-32
    8000118c:	ec06                	sd	ra,24(sp)
    8000118e:	e822                	sd	s0,16(sp)
    80001190:	e426                	sd	s1,8(sp)
    80001192:	e04a                	sd	s2,0(sp)
    80001194:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t)kalloc();
    80001196:	00000097          	auipc	ra,0x0
    8000119a:	964080e7          	jalr	-1692(ra) # 80000afa <kalloc>
    8000119e:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011a0:	6605                	lui	a2,0x1
    800011a2:	4581                	li	a1,0
    800011a4:	00000097          	auipc	ra,0x0
    800011a8:	b42080e7          	jalr	-1214(ra) # 80000ce6 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011ac:	4719                	li	a4,6
    800011ae:	6685                	lui	a3,0x1
    800011b0:	10000637          	lui	a2,0x10000
    800011b4:	100005b7          	lui	a1,0x10000
    800011b8:	8526                	mv	a0,s1
    800011ba:	00000097          	auipc	ra,0x0
    800011be:	fa0080e7          	jalr	-96(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c2:	4719                	li	a4,6
    800011c4:	6685                	lui	a3,0x1
    800011c6:	10001637          	lui	a2,0x10001
    800011ca:	100015b7          	lui	a1,0x10001
    800011ce:	8526                	mv	a0,s1
    800011d0:	00000097          	auipc	ra,0x0
    800011d4:	f8a080e7          	jalr	-118(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011d8:	4719                	li	a4,6
    800011da:	004006b7          	lui	a3,0x400
    800011de:	0c000637          	lui	a2,0xc000
    800011e2:	0c0005b7          	lui	a1,0xc000
    800011e6:	8526                	mv	a0,s1
    800011e8:	00000097          	auipc	ra,0x0
    800011ec:	f72080e7          	jalr	-142(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext - KERNBASE, PTE_R | PTE_X);
    800011f0:	00007917          	auipc	s2,0x7
    800011f4:	e1090913          	addi	s2,s2,-496 # 80008000 <etext>
    800011f8:	4729                	li	a4,10
    800011fa:	80007697          	auipc	a3,0x80007
    800011fe:	e0668693          	addi	a3,a3,-506 # 8000 <_entry-0x7fff8000>
    80001202:	4605                	li	a2,1
    80001204:	067e                	slli	a2,a2,0x1f
    80001206:	85b2                	mv	a1,a2
    80001208:	8526                	mv	a0,s1
    8000120a:	00000097          	auipc	ra,0x0
    8000120e:	f50080e7          	jalr	-176(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP - (uint64)etext, PTE_R | PTE_W);
    80001212:	4719                	li	a4,6
    80001214:	46c5                	li	a3,17
    80001216:	06ee                	slli	a3,a3,0x1b
    80001218:	412686b3          	sub	a3,a3,s2
    8000121c:	864a                	mv	a2,s2
    8000121e:	85ca                	mv	a1,s2
    80001220:	8526                	mv	a0,s1
    80001222:	00000097          	auipc	ra,0x0
    80001226:	f38080e7          	jalr	-200(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000122a:	4729                	li	a4,10
    8000122c:	6685                	lui	a3,0x1
    8000122e:	00006617          	auipc	a2,0x6
    80001232:	dd260613          	addi	a2,a2,-558 # 80007000 <_trampoline>
    80001236:	040005b7          	lui	a1,0x4000
    8000123a:	15fd                	addi	a1,a1,-1
    8000123c:	05b2                	slli	a1,a1,0xc
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	f1a080e7          	jalr	-230(ra) # 8000115a <kvmmap>
  proc_mapstacks(kpgtbl);
    80001248:	8526                	mv	a0,s1
    8000124a:	00000097          	auipc	ra,0x0
    8000124e:	606080e7          	jalr	1542(ra) # 80001850 <proc_mapstacks>
}
    80001252:	8526                	mv	a0,s1
    80001254:	60e2                	ld	ra,24(sp)
    80001256:	6442                	ld	s0,16(sp)
    80001258:	64a2                	ld	s1,8(sp)
    8000125a:	6902                	ld	s2,0(sp)
    8000125c:	6105                	addi	sp,sp,32
    8000125e:	8082                	ret

0000000080001260 <kvminit>:
{
    80001260:	1141                	addi	sp,sp,-16
    80001262:	e406                	sd	ra,8(sp)
    80001264:	e022                	sd	s0,0(sp)
    80001266:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001268:	00000097          	auipc	ra,0x0
    8000126c:	f22080e7          	jalr	-222(ra) # 8000118a <kvmmake>
    80001270:	00008797          	auipc	a5,0x8
    80001274:	90a7b823          	sd	a0,-1776(a5) # 80008b80 <kernel_pagetable>
}
    80001278:	60a2                	ld	ra,8(sp)
    8000127a:	6402                	ld	s0,0(sp)
    8000127c:	0141                	addi	sp,sp,16
    8000127e:	8082                	ret

0000000080001280 <uvmunmap>:

// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001280:	715d                	addi	sp,sp,-80
    80001282:	e486                	sd	ra,72(sp)
    80001284:	e0a2                	sd	s0,64(sp)
    80001286:	fc26                	sd	s1,56(sp)
    80001288:	f84a                	sd	s2,48(sp)
    8000128a:	f44e                	sd	s3,40(sp)
    8000128c:	f052                	sd	s4,32(sp)
    8000128e:	ec56                	sd	s5,24(sp)
    80001290:	e85a                	sd	s6,16(sp)
    80001292:	e45e                	sd	s7,8(sp)
    80001294:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if ((va % PGSIZE) != 0)
    80001296:	03459793          	slli	a5,a1,0x34
    8000129a:	e795                	bnez	a5,800012c6 <uvmunmap+0x46>
    8000129c:	8a2a                	mv	s4,a0
    8000129e:	892e                	mv	s2,a1
    800012a0:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    800012a2:	0632                	slli	a2,a2,0xc
    800012a4:	00b609b3          	add	s3,a2,a1
  {
    if ((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if ((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if (PTE_FLAGS(*pte) == PTE_V)
    800012a8:	4b85                	li	s7,1
  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    800012aa:	6b05                	lui	s6,0x1
    800012ac:	0735e863          	bltu	a1,s3,8000131c <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void *)pa);
    }
    *pte = 0;
  }
}
    800012b0:	60a6                	ld	ra,72(sp)
    800012b2:	6406                	ld	s0,64(sp)
    800012b4:	74e2                	ld	s1,56(sp)
    800012b6:	7942                	ld	s2,48(sp)
    800012b8:	79a2                	ld	s3,40(sp)
    800012ba:	7a02                	ld	s4,32(sp)
    800012bc:	6ae2                	ld	s5,24(sp)
    800012be:	6b42                	ld	s6,16(sp)
    800012c0:	6ba2                	ld	s7,8(sp)
    800012c2:	6161                	addi	sp,sp,80
    800012c4:	8082                	ret
    panic("uvmunmap: not aligned");
    800012c6:	00007517          	auipc	a0,0x7
    800012ca:	e3a50513          	addi	a0,a0,-454 # 80008100 <digits+0xc0>
    800012ce:	fffff097          	auipc	ra,0xfffff
    800012d2:	276080e7          	jalr	630(ra) # 80000544 <panic>
      panic("uvmunmap: walk");
    800012d6:	00007517          	auipc	a0,0x7
    800012da:	e4250513          	addi	a0,a0,-446 # 80008118 <digits+0xd8>
    800012de:	fffff097          	auipc	ra,0xfffff
    800012e2:	266080e7          	jalr	614(ra) # 80000544 <panic>
      panic("uvmunmap: not mapped");
    800012e6:	00007517          	auipc	a0,0x7
    800012ea:	e4250513          	addi	a0,a0,-446 # 80008128 <digits+0xe8>
    800012ee:	fffff097          	auipc	ra,0xfffff
    800012f2:	256080e7          	jalr	598(ra) # 80000544 <panic>
      panic("uvmunmap: not a leaf");
    800012f6:	00007517          	auipc	a0,0x7
    800012fa:	e4a50513          	addi	a0,a0,-438 # 80008140 <digits+0x100>
    800012fe:	fffff097          	auipc	ra,0xfffff
    80001302:	246080e7          	jalr	582(ra) # 80000544 <panic>
      uint64 pa = PTE2PA(*pte);
    80001306:	8129                	srli	a0,a0,0xa
      kfree((void *)pa);
    80001308:	0532                	slli	a0,a0,0xc
    8000130a:	fffff097          	auipc	ra,0xfffff
    8000130e:	6f4080e7          	jalr	1780(ra) # 800009fe <kfree>
    *pte = 0;
    80001312:	0004b023          	sd	zero,0(s1)
  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    80001316:	995a                	add	s2,s2,s6
    80001318:	f9397ce3          	bgeu	s2,s3,800012b0 <uvmunmap+0x30>
    if ((pte = walk(pagetable, a, 0)) == 0)
    8000131c:	4601                	li	a2,0
    8000131e:	85ca                	mv	a1,s2
    80001320:	8552                	mv	a0,s4
    80001322:	00000097          	auipc	ra,0x0
    80001326:	cb0080e7          	jalr	-848(ra) # 80000fd2 <walk>
    8000132a:	84aa                	mv	s1,a0
    8000132c:	d54d                	beqz	a0,800012d6 <uvmunmap+0x56>
    if ((*pte & PTE_V) == 0)
    8000132e:	6108                	ld	a0,0(a0)
    80001330:	00157793          	andi	a5,a0,1
    80001334:	dbcd                	beqz	a5,800012e6 <uvmunmap+0x66>
    if (PTE_FLAGS(*pte) == PTE_V)
    80001336:	3ff57793          	andi	a5,a0,1023
    8000133a:	fb778ee3          	beq	a5,s7,800012f6 <uvmunmap+0x76>
    if (do_free)
    8000133e:	fc0a8ae3          	beqz	s5,80001312 <uvmunmap+0x92>
    80001342:	b7d1                	j	80001306 <uvmunmap+0x86>

0000000080001344 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001344:	1101                	addi	sp,sp,-32
    80001346:	ec06                	sd	ra,24(sp)
    80001348:	e822                	sd	s0,16(sp)
    8000134a:	e426                	sd	s1,8(sp)
    8000134c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t)kalloc();
    8000134e:	fffff097          	auipc	ra,0xfffff
    80001352:	7ac080e7          	jalr	1964(ra) # 80000afa <kalloc>
    80001356:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001358:	c519                	beqz	a0,80001366 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000135a:	6605                	lui	a2,0x1
    8000135c:	4581                	li	a1,0
    8000135e:	00000097          	auipc	ra,0x0
    80001362:	988080e7          	jalr	-1656(ra) # 80000ce6 <memset>
  return pagetable;
}
    80001366:	8526                	mv	a0,s1
    80001368:	60e2                	ld	ra,24(sp)
    8000136a:	6442                	ld	s0,16(sp)
    8000136c:	64a2                	ld	s1,8(sp)
    8000136e:	6105                	addi	sp,sp,32
    80001370:	8082                	ret

0000000080001372 <uvmfirst>:

// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001372:	7179                	addi	sp,sp,-48
    80001374:	f406                	sd	ra,40(sp)
    80001376:	f022                	sd	s0,32(sp)
    80001378:	ec26                	sd	s1,24(sp)
    8000137a:	e84a                	sd	s2,16(sp)
    8000137c:	e44e                	sd	s3,8(sp)
    8000137e:	e052                	sd	s4,0(sp)
    80001380:	1800                	addi	s0,sp,48
  char *mem;

  if (sz >= PGSIZE)
    80001382:	6785                	lui	a5,0x1
    80001384:	04f67863          	bgeu	a2,a5,800013d4 <uvmfirst+0x62>
    80001388:	8a2a                	mv	s4,a0
    8000138a:	89ae                	mv	s3,a1
    8000138c:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000138e:	fffff097          	auipc	ra,0xfffff
    80001392:	76c080e7          	jalr	1900(ra) # 80000afa <kalloc>
    80001396:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001398:	6605                	lui	a2,0x1
    8000139a:	4581                	li	a1,0
    8000139c:	00000097          	auipc	ra,0x0
    800013a0:	94a080e7          	jalr	-1718(ra) # 80000ce6 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W | PTE_R | PTE_X | PTE_U);
    800013a4:	4779                	li	a4,30
    800013a6:	86ca                	mv	a3,s2
    800013a8:	6605                	lui	a2,0x1
    800013aa:	4581                	li	a1,0
    800013ac:	8552                	mv	a0,s4
    800013ae:	00000097          	auipc	ra,0x0
    800013b2:	d0c080e7          	jalr	-756(ra) # 800010ba <mappages>
  memmove(mem, src, sz);
    800013b6:	8626                	mv	a2,s1
    800013b8:	85ce                	mv	a1,s3
    800013ba:	854a                	mv	a0,s2
    800013bc:	00000097          	auipc	ra,0x0
    800013c0:	98a080e7          	jalr	-1654(ra) # 80000d46 <memmove>
}
    800013c4:	70a2                	ld	ra,40(sp)
    800013c6:	7402                	ld	s0,32(sp)
    800013c8:	64e2                	ld	s1,24(sp)
    800013ca:	6942                	ld	s2,16(sp)
    800013cc:	69a2                	ld	s3,8(sp)
    800013ce:	6a02                	ld	s4,0(sp)
    800013d0:	6145                	addi	sp,sp,48
    800013d2:	8082                	ret
    panic("uvmfirst: more than a page");
    800013d4:	00007517          	auipc	a0,0x7
    800013d8:	d8450513          	addi	a0,a0,-636 # 80008158 <digits+0x118>
    800013dc:	fffff097          	auipc	ra,0xfffff
    800013e0:	168080e7          	jalr	360(ra) # 80000544 <panic>

00000000800013e4 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013e4:	1101                	addi	sp,sp,-32
    800013e6:	ec06                	sd	ra,24(sp)
    800013e8:	e822                	sd	s0,16(sp)
    800013ea:	e426                	sd	s1,8(sp)
    800013ec:	1000                	addi	s0,sp,32
  if (newsz >= oldsz)
    return oldsz;
    800013ee:	84ae                	mv	s1,a1
  if (newsz >= oldsz)
    800013f0:	00b67d63          	bgeu	a2,a1,8000140a <uvmdealloc+0x26>
    800013f4:	84b2                	mv	s1,a2

  if (PGROUNDUP(newsz) < PGROUNDUP(oldsz))
    800013f6:	6785                	lui	a5,0x1
    800013f8:	17fd                	addi	a5,a5,-1
    800013fa:	00f60733          	add	a4,a2,a5
    800013fe:	767d                	lui	a2,0xfffff
    80001400:	8f71                	and	a4,a4,a2
    80001402:	97ae                	add	a5,a5,a1
    80001404:	8ff1                	and	a5,a5,a2
    80001406:	00f76863          	bltu	a4,a5,80001416 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000140a:	8526                	mv	a0,s1
    8000140c:	60e2                	ld	ra,24(sp)
    8000140e:	6442                	ld	s0,16(sp)
    80001410:	64a2                	ld	s1,8(sp)
    80001412:	6105                	addi	sp,sp,32
    80001414:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001416:	8f99                	sub	a5,a5,a4
    80001418:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000141a:	4685                	li	a3,1
    8000141c:	0007861b          	sext.w	a2,a5
    80001420:	85ba                	mv	a1,a4
    80001422:	00000097          	auipc	ra,0x0
    80001426:	e5e080e7          	jalr	-418(ra) # 80001280 <uvmunmap>
    8000142a:	b7c5                	j	8000140a <uvmdealloc+0x26>

000000008000142c <uvmalloc>:
  if (newsz < oldsz)
    8000142c:	0ab66563          	bltu	a2,a1,800014d6 <uvmalloc+0xaa>
{
    80001430:	7139                	addi	sp,sp,-64
    80001432:	fc06                	sd	ra,56(sp)
    80001434:	f822                	sd	s0,48(sp)
    80001436:	f426                	sd	s1,40(sp)
    80001438:	f04a                	sd	s2,32(sp)
    8000143a:	ec4e                	sd	s3,24(sp)
    8000143c:	e852                	sd	s4,16(sp)
    8000143e:	e456                	sd	s5,8(sp)
    80001440:	e05a                	sd	s6,0(sp)
    80001442:	0080                	addi	s0,sp,64
    80001444:	8aaa                	mv	s5,a0
    80001446:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001448:	6985                	lui	s3,0x1
    8000144a:	19fd                	addi	s3,s3,-1
    8000144c:	95ce                	add	a1,a1,s3
    8000144e:	79fd                	lui	s3,0xfffff
    80001450:	0135f9b3          	and	s3,a1,s3
  for (a = oldsz; a < newsz; a += PGSIZE)
    80001454:	08c9f363          	bgeu	s3,a2,800014da <uvmalloc+0xae>
    80001458:	894e                	mv	s2,s3
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    8000145a:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000145e:	fffff097          	auipc	ra,0xfffff
    80001462:	69c080e7          	jalr	1692(ra) # 80000afa <kalloc>
    80001466:	84aa                	mv	s1,a0
    if (mem == 0)
    80001468:	c51d                	beqz	a0,80001496 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000146a:	6605                	lui	a2,0x1
    8000146c:	4581                	li	a1,0
    8000146e:	00000097          	auipc	ra,0x0
    80001472:	878080e7          	jalr	-1928(ra) # 80000ce6 <memset>
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    80001476:	875a                	mv	a4,s6
    80001478:	86a6                	mv	a3,s1
    8000147a:	6605                	lui	a2,0x1
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	c3a080e7          	jalr	-966(ra) # 800010ba <mappages>
    80001488:	e90d                	bnez	a0,800014ba <uvmalloc+0x8e>
  for (a = oldsz; a < newsz; a += PGSIZE)
    8000148a:	6785                	lui	a5,0x1
    8000148c:	993e                	add	s2,s2,a5
    8000148e:	fd4968e3          	bltu	s2,s4,8000145e <uvmalloc+0x32>
  return newsz;
    80001492:	8552                	mv	a0,s4
    80001494:	a809                	j	800014a6 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f48080e7          	jalr	-184(ra) # 800013e4 <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
}
    800014a6:	70e2                	ld	ra,56(sp)
    800014a8:	7442                	ld	s0,48(sp)
    800014aa:	74a2                	ld	s1,40(sp)
    800014ac:	7902                	ld	s2,32(sp)
    800014ae:	69e2                	ld	s3,24(sp)
    800014b0:	6a42                	ld	s4,16(sp)
    800014b2:	6aa2                	ld	s5,8(sp)
    800014b4:	6b02                	ld	s6,0(sp)
    800014b6:	6121                	addi	sp,sp,64
    800014b8:	8082                	ret
      kfree(mem);
    800014ba:	8526                	mv	a0,s1
    800014bc:	fffff097          	auipc	ra,0xfffff
    800014c0:	542080e7          	jalr	1346(ra) # 800009fe <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014c4:	864e                	mv	a2,s3
    800014c6:	85ca                	mv	a1,s2
    800014c8:	8556                	mv	a0,s5
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	f1a080e7          	jalr	-230(ra) # 800013e4 <uvmdealloc>
      return 0;
    800014d2:	4501                	li	a0,0
    800014d4:	bfc9                	j	800014a6 <uvmalloc+0x7a>
    return oldsz;
    800014d6:	852e                	mv	a0,a1
}
    800014d8:	8082                	ret
  return newsz;
    800014da:	8532                	mv	a0,a2
    800014dc:	b7e9                	j	800014a6 <uvmalloc+0x7a>

00000000800014de <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void freewalk(pagetable_t pagetable)
{
    800014de:	7179                	addi	sp,sp,-48
    800014e0:	f406                	sd	ra,40(sp)
    800014e2:	f022                	sd	s0,32(sp)
    800014e4:	ec26                	sd	s1,24(sp)
    800014e6:	e84a                	sd	s2,16(sp)
    800014e8:	e44e                	sd	s3,8(sp)
    800014ea:	e052                	sd	s4,0(sp)
    800014ec:	1800                	addi	s0,sp,48
    800014ee:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for (int i = 0; i < 512; i++)
    800014f0:	84aa                	mv	s1,a0
    800014f2:	6905                	lui	s2,0x1
    800014f4:	992a                	add	s2,s2,a0
  {
    pte_t pte = pagetable[i];
    if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
    800014f6:	4985                	li	s3,1
    800014f8:	a821                	j	80001510 <freewalk+0x32>
    {
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014fa:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014fc:	0532                	slli	a0,a0,0xc
    800014fe:	00000097          	auipc	ra,0x0
    80001502:	fe0080e7          	jalr	-32(ra) # 800014de <freewalk>
      pagetable[i] = 0;
    80001506:	0004b023          	sd	zero,0(s1)
  for (int i = 0; i < 512; i++)
    8000150a:	04a1                	addi	s1,s1,8
    8000150c:	03248163          	beq	s1,s2,8000152e <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001510:	6088                	ld	a0,0(s1)
    if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
    80001512:	00f57793          	andi	a5,a0,15
    80001516:	ff3782e3          	beq	a5,s3,800014fa <freewalk+0x1c>
    }
    else if (pte & PTE_V)
    8000151a:	8905                	andi	a0,a0,1
    8000151c:	d57d                	beqz	a0,8000150a <freewalk+0x2c>
    {
      panic("freewalk: leaf");
    8000151e:	00007517          	auipc	a0,0x7
    80001522:	c5a50513          	addi	a0,a0,-934 # 80008178 <digits+0x138>
    80001526:	fffff097          	auipc	ra,0xfffff
    8000152a:	01e080e7          	jalr	30(ra) # 80000544 <panic>
    }
  }
  kfree((void *)pagetable);
    8000152e:	8552                	mv	a0,s4
    80001530:	fffff097          	auipc	ra,0xfffff
    80001534:	4ce080e7          	jalr	1230(ra) # 800009fe <kfree>
}
    80001538:	70a2                	ld	ra,40(sp)
    8000153a:	7402                	ld	s0,32(sp)
    8000153c:	64e2                	ld	s1,24(sp)
    8000153e:	6942                	ld	s2,16(sp)
    80001540:	69a2                	ld	s3,8(sp)
    80001542:	6a02                	ld	s4,0(sp)
    80001544:	6145                	addi	sp,sp,48
    80001546:	8082                	ret

0000000080001548 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001548:	1101                	addi	sp,sp,-32
    8000154a:	ec06                	sd	ra,24(sp)
    8000154c:	e822                	sd	s0,16(sp)
    8000154e:	e426                	sd	s1,8(sp)
    80001550:	1000                	addi	s0,sp,32
    80001552:	84aa                	mv	s1,a0
  if (sz > 0)
    80001554:	e999                	bnez	a1,8000156a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz) / PGSIZE, 1);
  freewalk(pagetable);
    80001556:	8526                	mv	a0,s1
    80001558:	00000097          	auipc	ra,0x0
    8000155c:	f86080e7          	jalr	-122(ra) # 800014de <freewalk>
}
    80001560:	60e2                	ld	ra,24(sp)
    80001562:	6442                	ld	s0,16(sp)
    80001564:	64a2                	ld	s1,8(sp)
    80001566:	6105                	addi	sp,sp,32
    80001568:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz) / PGSIZE, 1);
    8000156a:	6605                	lui	a2,0x1
    8000156c:	167d                	addi	a2,a2,-1
    8000156e:	962e                	add	a2,a2,a1
    80001570:	4685                	li	a3,1
    80001572:	8231                	srli	a2,a2,0xc
    80001574:	4581                	li	a1,0
    80001576:	00000097          	auipc	ra,0x0
    8000157a:	d0a080e7          	jalr	-758(ra) # 80001280 <uvmunmap>
    8000157e:	bfe1                	j	80001556 <uvmfree+0xe>

0000000080001580 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for (i = 0; i < sz; i += PGSIZE)
    80001580:	c679                	beqz	a2,8000164e <uvmcopy+0xce>
{
    80001582:	715d                	addi	sp,sp,-80
    80001584:	e486                	sd	ra,72(sp)
    80001586:	e0a2                	sd	s0,64(sp)
    80001588:	fc26                	sd	s1,56(sp)
    8000158a:	f84a                	sd	s2,48(sp)
    8000158c:	f44e                	sd	s3,40(sp)
    8000158e:	f052                	sd	s4,32(sp)
    80001590:	ec56                	sd	s5,24(sp)
    80001592:	e85a                	sd	s6,16(sp)
    80001594:	e45e                	sd	s7,8(sp)
    80001596:	0880                	addi	s0,sp,80
    80001598:	8b2a                	mv	s6,a0
    8000159a:	8aae                	mv	s5,a1
    8000159c:	8a32                	mv	s4,a2
  for (i = 0; i < sz; i += PGSIZE)
    8000159e:	4981                	li	s3,0
  {
    if ((pte = walk(old, i, 0)) == 0)
    800015a0:	4601                	li	a2,0
    800015a2:	85ce                	mv	a1,s3
    800015a4:	855a                	mv	a0,s6
    800015a6:	00000097          	auipc	ra,0x0
    800015aa:	a2c080e7          	jalr	-1492(ra) # 80000fd2 <walk>
    800015ae:	c531                	beqz	a0,800015fa <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if ((*pte & PTE_V) == 0)
    800015b0:	6118                	ld	a4,0(a0)
    800015b2:	00177793          	andi	a5,a4,1
    800015b6:	cbb1                	beqz	a5,8000160a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015b8:	00a75593          	srli	a1,a4,0xa
    800015bc:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015c0:	3ff77493          	andi	s1,a4,1023
    // flags |= PTE_R;
    // flags &= (~PTE_W);
    if ((mem = kalloc()) == 0)
    800015c4:	fffff097          	auipc	ra,0xfffff
    800015c8:	536080e7          	jalr	1334(ra) # 80000afa <kalloc>
    800015cc:	892a                	mv	s2,a0
    800015ce:	c939                	beqz	a0,80001624 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char *)pa, PGSIZE);
    800015d0:	6605                	lui	a2,0x1
    800015d2:	85de                	mv	a1,s7
    800015d4:	fffff097          	auipc	ra,0xfffff
    800015d8:	772080e7          	jalr	1906(ra) # 80000d46 <memmove>
    if (mappages(new, i, PGSIZE, (uint64)mem, flags) != 0)
    800015dc:	8726                	mv	a4,s1
    800015de:	86ca                	mv	a3,s2
    800015e0:	6605                	lui	a2,0x1
    800015e2:	85ce                	mv	a1,s3
    800015e4:	8556                	mv	a0,s5
    800015e6:	00000097          	auipc	ra,0x0
    800015ea:	ad4080e7          	jalr	-1324(ra) # 800010ba <mappages>
    800015ee:	e515                	bnez	a0,8000161a <uvmcopy+0x9a>
  for (i = 0; i < sz; i += PGSIZE)
    800015f0:	6785                	lui	a5,0x1
    800015f2:	99be                	add	s3,s3,a5
    800015f4:	fb49e6e3          	bltu	s3,s4,800015a0 <uvmcopy+0x20>
    800015f8:	a081                	j	80001638 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015fa:	00007517          	auipc	a0,0x7
    800015fe:	b8e50513          	addi	a0,a0,-1138 # 80008188 <digits+0x148>
    80001602:	fffff097          	auipc	ra,0xfffff
    80001606:	f42080e7          	jalr	-190(ra) # 80000544 <panic>
      panic("uvmcopy: page not present");
    8000160a:	00007517          	auipc	a0,0x7
    8000160e:	b9e50513          	addi	a0,a0,-1122 # 800081a8 <digits+0x168>
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	f32080e7          	jalr	-206(ra) # 80000544 <panic>
    {
      kfree(mem);
    8000161a:	854a                	mv	a0,s2
    8000161c:	fffff097          	auipc	ra,0xfffff
    80001620:	3e2080e7          	jalr	994(ra) # 800009fe <kfree>
    }
  }
  return 0;

err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001624:	4685                	li	a3,1
    80001626:	00c9d613          	srli	a2,s3,0xc
    8000162a:	4581                	li	a1,0
    8000162c:	8556                	mv	a0,s5
    8000162e:	00000097          	auipc	ra,0x0
    80001632:	c52080e7          	jalr	-942(ra) # 80001280 <uvmunmap>
  return -1;
    80001636:	557d                	li	a0,-1
}
    80001638:	60a6                	ld	ra,72(sp)
    8000163a:	6406                	ld	s0,64(sp)
    8000163c:	74e2                	ld	s1,56(sp)
    8000163e:	7942                	ld	s2,48(sp)
    80001640:	79a2                	ld	s3,40(sp)
    80001642:	7a02                	ld	s4,32(sp)
    80001644:	6ae2                	ld	s5,24(sp)
    80001646:	6b42                	ld	s6,16(sp)
    80001648:	6ba2                	ld	s7,8(sp)
    8000164a:	6161                	addi	sp,sp,80
    8000164c:	8082                	ret
  return 0;
    8000164e:	4501                	li	a0,0
}
    80001650:	8082                	ret

0000000080001652 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void uvmclear(pagetable_t pagetable, uint64 va)
{
    80001652:	1141                	addi	sp,sp,-16
    80001654:	e406                	sd	ra,8(sp)
    80001656:	e022                	sd	s0,0(sp)
    80001658:	0800                	addi	s0,sp,16
  pte_t *pte;

  pte = walk(pagetable, va, 0);
    8000165a:	4601                	li	a2,0
    8000165c:	00000097          	auipc	ra,0x0
    80001660:	976080e7          	jalr	-1674(ra) # 80000fd2 <walk>
  if (pte == 0)
    80001664:	c901                	beqz	a0,80001674 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001666:	611c                	ld	a5,0(a0)
    80001668:	9bbd                	andi	a5,a5,-17
    8000166a:	e11c                	sd	a5,0(a0)
}
    8000166c:	60a2                	ld	ra,8(sp)
    8000166e:	6402                	ld	s0,0(sp)
    80001670:	0141                	addi	sp,sp,16
    80001672:	8082                	ret
    panic("uvmclear");
    80001674:	00007517          	auipc	a0,0x7
    80001678:	b5450513          	addi	a0,a0,-1196 # 800081c8 <digits+0x188>
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	ec8080e7          	jalr	-312(ra) # 80000544 <panic>

0000000080001684 <copyout>:
// Return 0 on success, -1 on error.
int copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while (len > 0)
    80001684:	c6bd                	beqz	a3,800016f2 <copyout+0x6e>
{
    80001686:	715d                	addi	sp,sp,-80
    80001688:	e486                	sd	ra,72(sp)
    8000168a:	e0a2                	sd	s0,64(sp)
    8000168c:	fc26                	sd	s1,56(sp)
    8000168e:	f84a                	sd	s2,48(sp)
    80001690:	f44e                	sd	s3,40(sp)
    80001692:	f052                	sd	s4,32(sp)
    80001694:	ec56                	sd	s5,24(sp)
    80001696:	e85a                	sd	s6,16(sp)
    80001698:	e45e                	sd	s7,8(sp)
    8000169a:	e062                	sd	s8,0(sp)
    8000169c:	0880                	addi	s0,sp,80
    8000169e:	8b2a                	mv	s6,a0
    800016a0:	8c2e                	mv	s8,a1
    800016a2:	8a32                	mv	s4,a2
    800016a4:	89b6                	mv	s3,a3
  {
    va0 = PGROUNDDOWN(dstva);
    800016a6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016a8:	6a85                	lui	s5,0x1
    800016aa:	a015                	j	800016ce <copyout+0x4a>
    if (n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016ac:	9562                	add	a0,a0,s8
    800016ae:	0004861b          	sext.w	a2,s1
    800016b2:	85d2                	mv	a1,s4
    800016b4:	41250533          	sub	a0,a0,s2
    800016b8:	fffff097          	auipc	ra,0xfffff
    800016bc:	68e080e7          	jalr	1678(ra) # 80000d46 <memmove>

    len -= n;
    800016c0:	409989b3          	sub	s3,s3,s1
    src += n;
    800016c4:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016c6:	01590c33          	add	s8,s2,s5
  while (len > 0)
    800016ca:	02098263          	beqz	s3,800016ee <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016ce:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016d2:	85ca                	mv	a1,s2
    800016d4:	855a                	mv	a0,s6
    800016d6:	00000097          	auipc	ra,0x0
    800016da:	9a2080e7          	jalr	-1630(ra) # 80001078 <walkaddr>
    if (pa0 == 0)
    800016de:	cd01                	beqz	a0,800016f6 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016e0:	418904b3          	sub	s1,s2,s8
    800016e4:	94d6                	add	s1,s1,s5
    if (n > len)
    800016e6:	fc99f3e3          	bgeu	s3,s1,800016ac <copyout+0x28>
    800016ea:	84ce                	mv	s1,s3
    800016ec:	b7c1                	j	800016ac <copyout+0x28>
  }
  return 0;
    800016ee:	4501                	li	a0,0
    800016f0:	a021                	j	800016f8 <copyout+0x74>
    800016f2:	4501                	li	a0,0
}
    800016f4:	8082                	ret
      return -1;
    800016f6:	557d                	li	a0,-1
}
    800016f8:	60a6                	ld	ra,72(sp)
    800016fa:	6406                	ld	s0,64(sp)
    800016fc:	74e2                	ld	s1,56(sp)
    800016fe:	7942                	ld	s2,48(sp)
    80001700:	79a2                	ld	s3,40(sp)
    80001702:	7a02                	ld	s4,32(sp)
    80001704:	6ae2                	ld	s5,24(sp)
    80001706:	6b42                	ld	s6,16(sp)
    80001708:	6ba2                	ld	s7,8(sp)
    8000170a:	6c02                	ld	s8,0(sp)
    8000170c:	6161                	addi	sp,sp,80
    8000170e:	8082                	ret

0000000080001710 <copyin>:
// Return 0 on success, -1 on error.
int copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while (len > 0)
    80001710:	c6bd                	beqz	a3,8000177e <copyin+0x6e>
{
    80001712:	715d                	addi	sp,sp,-80
    80001714:	e486                	sd	ra,72(sp)
    80001716:	e0a2                	sd	s0,64(sp)
    80001718:	fc26                	sd	s1,56(sp)
    8000171a:	f84a                	sd	s2,48(sp)
    8000171c:	f44e                	sd	s3,40(sp)
    8000171e:	f052                	sd	s4,32(sp)
    80001720:	ec56                	sd	s5,24(sp)
    80001722:	e85a                	sd	s6,16(sp)
    80001724:	e45e                	sd	s7,8(sp)
    80001726:	e062                	sd	s8,0(sp)
    80001728:	0880                	addi	s0,sp,80
    8000172a:	8b2a                	mv	s6,a0
    8000172c:	8a2e                	mv	s4,a1
    8000172e:	8c32                	mv	s8,a2
    80001730:	89b6                	mv	s3,a3
  {
    va0 = PGROUNDDOWN(srcva);
    80001732:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001734:	6a85                	lui	s5,0x1
    80001736:	a015                	j	8000175a <copyin+0x4a>
    if (n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001738:	9562                	add	a0,a0,s8
    8000173a:	0004861b          	sext.w	a2,s1
    8000173e:	412505b3          	sub	a1,a0,s2
    80001742:	8552                	mv	a0,s4
    80001744:	fffff097          	auipc	ra,0xfffff
    80001748:	602080e7          	jalr	1538(ra) # 80000d46 <memmove>

    len -= n;
    8000174c:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001750:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001752:	01590c33          	add	s8,s2,s5
  while (len > 0)
    80001756:	02098263          	beqz	s3,8000177a <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000175a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000175e:	85ca                	mv	a1,s2
    80001760:	855a                	mv	a0,s6
    80001762:	00000097          	auipc	ra,0x0
    80001766:	916080e7          	jalr	-1770(ra) # 80001078 <walkaddr>
    if (pa0 == 0)
    8000176a:	cd01                	beqz	a0,80001782 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000176c:	418904b3          	sub	s1,s2,s8
    80001770:	94d6                	add	s1,s1,s5
    if (n > len)
    80001772:	fc99f3e3          	bgeu	s3,s1,80001738 <copyin+0x28>
    80001776:	84ce                	mv	s1,s3
    80001778:	b7c1                	j	80001738 <copyin+0x28>
  }
  return 0;
    8000177a:	4501                	li	a0,0
    8000177c:	a021                	j	80001784 <copyin+0x74>
    8000177e:	4501                	li	a0,0
}
    80001780:	8082                	ret
      return -1;
    80001782:	557d                	li	a0,-1
}
    80001784:	60a6                	ld	ra,72(sp)
    80001786:	6406                	ld	s0,64(sp)
    80001788:	74e2                	ld	s1,56(sp)
    8000178a:	7942                	ld	s2,48(sp)
    8000178c:	79a2                	ld	s3,40(sp)
    8000178e:	7a02                	ld	s4,32(sp)
    80001790:	6ae2                	ld	s5,24(sp)
    80001792:	6b42                	ld	s6,16(sp)
    80001794:	6ba2                	ld	s7,8(sp)
    80001796:	6c02                	ld	s8,0(sp)
    80001798:	6161                	addi	sp,sp,80
    8000179a:	8082                	ret

000000008000179c <copyinstr>:
int copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while (got_null == 0 && max > 0)
    8000179c:	c6c5                	beqz	a3,80001844 <copyinstr+0xa8>
{
    8000179e:	715d                	addi	sp,sp,-80
    800017a0:	e486                	sd	ra,72(sp)
    800017a2:	e0a2                	sd	s0,64(sp)
    800017a4:	fc26                	sd	s1,56(sp)
    800017a6:	f84a                	sd	s2,48(sp)
    800017a8:	f44e                	sd	s3,40(sp)
    800017aa:	f052                	sd	s4,32(sp)
    800017ac:	ec56                	sd	s5,24(sp)
    800017ae:	e85a                	sd	s6,16(sp)
    800017b0:	e45e                	sd	s7,8(sp)
    800017b2:	0880                	addi	s0,sp,80
    800017b4:	8a2a                	mv	s4,a0
    800017b6:	8b2e                	mv	s6,a1
    800017b8:	8bb2                	mv	s7,a2
    800017ba:	84b6                	mv	s1,a3
  {
    va0 = PGROUNDDOWN(srcva);
    800017bc:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017be:	6985                	lui	s3,0x1
    800017c0:	a035                	j	800017ec <copyinstr+0x50>
    char *p = (char *)(pa0 + (srcva - va0));
    while (n > 0)
    {
      if (*p == '\0')
      {
        *dst = '\0';
    800017c2:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017c6:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if (got_null)
    800017c8:	0017b793          	seqz	a5,a5
    800017cc:	40f00533          	neg	a0,a5
  }
  else
  {
    return -1;
  }
}
    800017d0:	60a6                	ld	ra,72(sp)
    800017d2:	6406                	ld	s0,64(sp)
    800017d4:	74e2                	ld	s1,56(sp)
    800017d6:	7942                	ld	s2,48(sp)
    800017d8:	79a2                	ld	s3,40(sp)
    800017da:	7a02                	ld	s4,32(sp)
    800017dc:	6ae2                	ld	s5,24(sp)
    800017de:	6b42                	ld	s6,16(sp)
    800017e0:	6ba2                	ld	s7,8(sp)
    800017e2:	6161                	addi	sp,sp,80
    800017e4:	8082                	ret
    srcva = va0 + PGSIZE;
    800017e6:	01390bb3          	add	s7,s2,s3
  while (got_null == 0 && max > 0)
    800017ea:	c8a9                	beqz	s1,8000183c <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017ec:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017f0:	85ca                	mv	a1,s2
    800017f2:	8552                	mv	a0,s4
    800017f4:	00000097          	auipc	ra,0x0
    800017f8:	884080e7          	jalr	-1916(ra) # 80001078 <walkaddr>
    if (pa0 == 0)
    800017fc:	c131                	beqz	a0,80001840 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017fe:	41790833          	sub	a6,s2,s7
    80001802:	984e                	add	a6,a6,s3
    if (n > max)
    80001804:	0104f363          	bgeu	s1,a6,8000180a <copyinstr+0x6e>
    80001808:	8826                	mv	a6,s1
    char *p = (char *)(pa0 + (srcva - va0));
    8000180a:	955e                	add	a0,a0,s7
    8000180c:	41250533          	sub	a0,a0,s2
    while (n > 0)
    80001810:	fc080be3          	beqz	a6,800017e6 <copyinstr+0x4a>
    80001814:	985a                	add	a6,a6,s6
    80001816:	87da                	mv	a5,s6
      if (*p == '\0')
    80001818:	41650633          	sub	a2,a0,s6
    8000181c:	14fd                	addi	s1,s1,-1
    8000181e:	9b26                	add	s6,s6,s1
    80001820:	00f60733          	add	a4,a2,a5
    80001824:	00074703          	lbu	a4,0(a4)
    80001828:	df49                	beqz	a4,800017c2 <copyinstr+0x26>
        *dst = *p;
    8000182a:	00e78023          	sb	a4,0(a5)
      --max;
    8000182e:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001832:	0785                	addi	a5,a5,1
    while (n > 0)
    80001834:	ff0796e3          	bne	a5,a6,80001820 <copyinstr+0x84>
      dst++;
    80001838:	8b42                	mv	s6,a6
    8000183a:	b775                	j	800017e6 <copyinstr+0x4a>
    8000183c:	4781                	li	a5,0
    8000183e:	b769                	j	800017c8 <copyinstr+0x2c>
      return -1;
    80001840:	557d                	li	a0,-1
    80001842:	b779                	j	800017d0 <copyinstr+0x34>
  int got_null = 0;
    80001844:	4781                	li	a5,0
  if (got_null)
    80001846:	0017b793          	seqz	a5,a5
    8000184a:	40f00533          	neg	a0,a5
}
    8000184e:	8082                	ret

0000000080001850 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001850:	7139                	addi	sp,sp,-64
    80001852:	fc06                	sd	ra,56(sp)
    80001854:	f822                	sd	s0,48(sp)
    80001856:	f426                	sd	s1,40(sp)
    80001858:	f04a                	sd	s2,32(sp)
    8000185a:	ec4e                	sd	s3,24(sp)
    8000185c:	e852                	sd	s4,16(sp)
    8000185e:	e456                	sd	s5,8(sp)
    80001860:	e05a                	sd	s6,0(sp)
    80001862:	0080                	addi	s0,sp,64
    80001864:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001866:	00010497          	auipc	s1,0x10
    8000186a:	9ca48493          	addi	s1,s1,-1590 # 80011230 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    8000186e:	8b26                	mv	s6,s1
    80001870:	00006a97          	auipc	s5,0x6
    80001874:	790a8a93          	addi	s5,s5,1936 # 80008000 <etext>
    80001878:	04000937          	lui	s2,0x4000
    8000187c:	197d                	addi	s2,s2,-1
    8000187e:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001880:	00016a17          	auipc	s4,0x16
    80001884:	3b0a0a13          	addi	s4,s4,944 # 80017c30 <tickslock>
    char *pa = kalloc();
    80001888:	fffff097          	auipc	ra,0xfffff
    8000188c:	272080e7          	jalr	626(ra) # 80000afa <kalloc>
    80001890:	862a                	mv	a2,a0
    if (pa == 0)
    80001892:	c131                	beqz	a0,800018d6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001894:	416485b3          	sub	a1,s1,s6
    80001898:	858d                	srai	a1,a1,0x3
    8000189a:	000ab783          	ld	a5,0(s5)
    8000189e:	02f585b3          	mul	a1,a1,a5
    800018a2:	2585                	addiw	a1,a1,1
    800018a4:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018a8:	4719                	li	a4,6
    800018aa:	6685                	lui	a3,0x1
    800018ac:	40b905b3          	sub	a1,s2,a1
    800018b0:	854e                	mv	a0,s3
    800018b2:	00000097          	auipc	ra,0x0
    800018b6:	8a8080e7          	jalr	-1880(ra) # 8000115a <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018ba:	1a848493          	addi	s1,s1,424
    800018be:	fd4495e3          	bne	s1,s4,80001888 <proc_mapstacks+0x38>
  }
}
    800018c2:	70e2                	ld	ra,56(sp)
    800018c4:	7442                	ld	s0,48(sp)
    800018c6:	74a2                	ld	s1,40(sp)
    800018c8:	7902                	ld	s2,32(sp)
    800018ca:	69e2                	ld	s3,24(sp)
    800018cc:	6a42                	ld	s4,16(sp)
    800018ce:	6aa2                	ld	s5,8(sp)
    800018d0:	6b02                	ld	s6,0(sp)
    800018d2:	6121                	addi	sp,sp,64
    800018d4:	8082                	ret
      panic("kalloc");
    800018d6:	00007517          	auipc	a0,0x7
    800018da:	90250513          	addi	a0,a0,-1790 # 800081d8 <digits+0x198>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	c66080e7          	jalr	-922(ra) # 80000544 <panic>

00000000800018e6 <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018e6:	7139                	addi	sp,sp,-64
    800018e8:	fc06                	sd	ra,56(sp)
    800018ea:	f822                	sd	s0,48(sp)
    800018ec:	f426                	sd	s1,40(sp)
    800018ee:	f04a                	sd	s2,32(sp)
    800018f0:	ec4e                	sd	s3,24(sp)
    800018f2:	e852                	sd	s4,16(sp)
    800018f4:	e456                	sd	s5,8(sp)
    800018f6:	e05a                	sd	s6,0(sp)
    800018f8:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018fa:	00007597          	auipc	a1,0x7
    800018fe:	8e658593          	addi	a1,a1,-1818 # 800081e0 <digits+0x1a0>
    80001902:	0000f517          	auipc	a0,0xf
    80001906:	4fe50513          	addi	a0,a0,1278 # 80010e00 <pid_lock>
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	250080e7          	jalr	592(ra) # 80000b5a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001912:	00007597          	auipc	a1,0x7
    80001916:	8d658593          	addi	a1,a1,-1834 # 800081e8 <digits+0x1a8>
    8000191a:	0000f517          	auipc	a0,0xf
    8000191e:	4fe50513          	addi	a0,a0,1278 # 80010e18 <wait_lock>
    80001922:	fffff097          	auipc	ra,0xfffff
    80001926:	238080e7          	jalr	568(ra) # 80000b5a <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    8000192a:	00010497          	auipc	s1,0x10
    8000192e:	90648493          	addi	s1,s1,-1786 # 80011230 <proc>
  {
    initlock(&p->lock, "proc");
    80001932:	00007b17          	auipc	s6,0x7
    80001936:	8c6b0b13          	addi	s6,s6,-1850 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    8000193a:	8aa6                	mv	s5,s1
    8000193c:	00006a17          	auipc	s4,0x6
    80001940:	6c4a0a13          	addi	s4,s4,1732 # 80008000 <etext>
    80001944:	04000937          	lui	s2,0x4000
    80001948:	197d                	addi	s2,s2,-1
    8000194a:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    8000194c:	00016997          	auipc	s3,0x16
    80001950:	2e498993          	addi	s3,s3,740 # 80017c30 <tickslock>
    initlock(&p->lock, "proc");
    80001954:	85da                	mv	a1,s6
    80001956:	8526                	mv	a0,s1
    80001958:	fffff097          	auipc	ra,0xfffff
    8000195c:	202080e7          	jalr	514(ra) # 80000b5a <initlock>
    p->state = UNUSED;
    80001960:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001964:	415487b3          	sub	a5,s1,s5
    80001968:	878d                	srai	a5,a5,0x3
    8000196a:	000a3703          	ld	a4,0(s4)
    8000196e:	02e787b3          	mul	a5,a5,a4
    80001972:	2785                	addiw	a5,a5,1
    80001974:	00d7979b          	slliw	a5,a5,0xd
    80001978:	40f907b3          	sub	a5,s2,a5
    8000197c:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    8000197e:	1a848493          	addi	s1,s1,424
    80001982:	fd3499e3          	bne	s1,s3,80001954 <procinit+0x6e>
  }
}
    80001986:	70e2                	ld	ra,56(sp)
    80001988:	7442                	ld	s0,48(sp)
    8000198a:	74a2                	ld	s1,40(sp)
    8000198c:	7902                	ld	s2,32(sp)
    8000198e:	69e2                	ld	s3,24(sp)
    80001990:	6a42                	ld	s4,16(sp)
    80001992:	6aa2                	ld	s5,8(sp)
    80001994:	6b02                	ld	s6,0(sp)
    80001996:	6121                	addi	sp,sp,64
    80001998:	8082                	ret

000000008000199a <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    8000199a:	1141                	addi	sp,sp,-16
    8000199c:	e422                	sd	s0,8(sp)
    8000199e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp"
    800019a0:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019a2:	2501                	sext.w	a0,a0
    800019a4:	6422                	ld	s0,8(sp)
    800019a6:	0141                	addi	sp,sp,16
    800019a8:	8082                	ret

00000000800019aa <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    800019aa:	1141                	addi	sp,sp,-16
    800019ac:	e422                	sd	s0,8(sp)
    800019ae:	0800                	addi	s0,sp,16
    800019b0:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019b2:	2781                	sext.w	a5,a5
    800019b4:	079e                	slli	a5,a5,0x7
  return c;
}
    800019b6:	0000f517          	auipc	a0,0xf
    800019ba:	47a50513          	addi	a0,a0,1146 # 80010e30 <cpus>
    800019be:	953e                	add	a0,a0,a5
    800019c0:	6422                	ld	s0,8(sp)
    800019c2:	0141                	addi	sp,sp,16
    800019c4:	8082                	ret

00000000800019c6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019c6:	1101                	addi	sp,sp,-32
    800019c8:	ec06                	sd	ra,24(sp)
    800019ca:	e822                	sd	s0,16(sp)
    800019cc:	e426                	sd	s1,8(sp)
    800019ce:	1000                	addi	s0,sp,32
  push_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	1ce080e7          	jalr	462(ra) # 80000b9e <push_off>
    800019d8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019da:	2781                	sext.w	a5,a5
    800019dc:	079e                	slli	a5,a5,0x7
    800019de:	0000f717          	auipc	a4,0xf
    800019e2:	42270713          	addi	a4,a4,1058 # 80010e00 <pid_lock>
    800019e6:	97ba                	add	a5,a5,a4
    800019e8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ea:	fffff097          	auipc	ra,0xfffff
    800019ee:	254080e7          	jalr	596(ra) # 80000c3e <pop_off>
  return p;
}
    800019f2:	8526                	mv	a0,s1
    800019f4:	60e2                	ld	ra,24(sp)
    800019f6:	6442                	ld	s0,16(sp)
    800019f8:	64a2                	ld	s1,8(sp)
    800019fa:	6105                	addi	sp,sp,32
    800019fc:	8082                	ret

00000000800019fe <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019fe:	1141                	addi	sp,sp,-16
    80001a00:	e406                	sd	ra,8(sp)
    80001a02:	e022                	sd	s0,0(sp)
    80001a04:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a06:	00000097          	auipc	ra,0x0
    80001a0a:	fc0080e7          	jalr	-64(ra) # 800019c6 <myproc>
    80001a0e:	fffff097          	auipc	ra,0xfffff
    80001a12:	290080e7          	jalr	656(ra) # 80000c9e <release>

  if (first)
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	f7a7a783          	lw	a5,-134(a5) # 80008990 <first.1756>
    80001a1e:	eb89                	bnez	a5,80001a30 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a20:	00001097          	auipc	ra,0x1
    80001a24:	0ca080e7          	jalr	202(ra) # 80002aea <usertrapret>
}
    80001a28:	60a2                	ld	ra,8(sp)
    80001a2a:	6402                	ld	s0,0(sp)
    80001a2c:	0141                	addi	sp,sp,16
    80001a2e:	8082                	ret
    first = 0;
    80001a30:	00007797          	auipc	a5,0x7
    80001a34:	f607a023          	sw	zero,-160(a5) # 80008990 <first.1756>
    fsinit(ROOTDEV);
    80001a38:	4505                	li	a0,1
    80001a3a:	00002097          	auipc	ra,0x2
    80001a3e:	11e080e7          	jalr	286(ra) # 80003b58 <fsinit>
    80001a42:	bff9                	j	80001a20 <forkret+0x22>

0000000080001a44 <allocpid>:
{
    80001a44:	1101                	addi	sp,sp,-32
    80001a46:	ec06                	sd	ra,24(sp)
    80001a48:	e822                	sd	s0,16(sp)
    80001a4a:	e426                	sd	s1,8(sp)
    80001a4c:	e04a                	sd	s2,0(sp)
    80001a4e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a50:	0000f917          	auipc	s2,0xf
    80001a54:	3b090913          	addi	s2,s2,944 # 80010e00 <pid_lock>
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	190080e7          	jalr	400(ra) # 80000bea <acquire>
  pid = nextpid;
    80001a62:	00007797          	auipc	a5,0x7
    80001a66:	f3e78793          	addi	a5,a5,-194 # 800089a0 <nextpid>
    80001a6a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a6c:	0014871b          	addiw	a4,s1,1
    80001a70:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a72:	854a                	mv	a0,s2
    80001a74:	fffff097          	auipc	ra,0xfffff
    80001a78:	22a080e7          	jalr	554(ra) # 80000c9e <release>
}
    80001a7c:	8526                	mv	a0,s1
    80001a7e:	60e2                	ld	ra,24(sp)
    80001a80:	6442                	ld	s0,16(sp)
    80001a82:	64a2                	ld	s1,8(sp)
    80001a84:	6902                	ld	s2,0(sp)
    80001a86:	6105                	addi	sp,sp,32
    80001a88:	8082                	ret

0000000080001a8a <proc_pagetable>:
{
    80001a8a:	1101                	addi	sp,sp,-32
    80001a8c:	ec06                	sd	ra,24(sp)
    80001a8e:	e822                	sd	s0,16(sp)
    80001a90:	e426                	sd	s1,8(sp)
    80001a92:	e04a                	sd	s2,0(sp)
    80001a94:	1000                	addi	s0,sp,32
    80001a96:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a98:	00000097          	auipc	ra,0x0
    80001a9c:	8ac080e7          	jalr	-1876(ra) # 80001344 <uvmcreate>
    80001aa0:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001aa2:	c121                	beqz	a0,80001ae2 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aa4:	4729                	li	a4,10
    80001aa6:	00005697          	auipc	a3,0x5
    80001aaa:	55a68693          	addi	a3,a3,1370 # 80007000 <_trampoline>
    80001aae:	6605                	lui	a2,0x1
    80001ab0:	040005b7          	lui	a1,0x4000
    80001ab4:	15fd                	addi	a1,a1,-1
    80001ab6:	05b2                	slli	a1,a1,0xc
    80001ab8:	fffff097          	auipc	ra,0xfffff
    80001abc:	602080e7          	jalr	1538(ra) # 800010ba <mappages>
    80001ac0:	02054863          	bltz	a0,80001af0 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ac4:	4719                	li	a4,6
    80001ac6:	05893683          	ld	a3,88(s2)
    80001aca:	6605                	lui	a2,0x1
    80001acc:	020005b7          	lui	a1,0x2000
    80001ad0:	15fd                	addi	a1,a1,-1
    80001ad2:	05b6                	slli	a1,a1,0xd
    80001ad4:	8526                	mv	a0,s1
    80001ad6:	fffff097          	auipc	ra,0xfffff
    80001ada:	5e4080e7          	jalr	1508(ra) # 800010ba <mappages>
    80001ade:	02054163          	bltz	a0,80001b00 <proc_pagetable+0x76>
}
    80001ae2:	8526                	mv	a0,s1
    80001ae4:	60e2                	ld	ra,24(sp)
    80001ae6:	6442                	ld	s0,16(sp)
    80001ae8:	64a2                	ld	s1,8(sp)
    80001aea:	6902                	ld	s2,0(sp)
    80001aec:	6105                	addi	sp,sp,32
    80001aee:	8082                	ret
    uvmfree(pagetable, 0);
    80001af0:	4581                	li	a1,0
    80001af2:	8526                	mv	a0,s1
    80001af4:	00000097          	auipc	ra,0x0
    80001af8:	a54080e7          	jalr	-1452(ra) # 80001548 <uvmfree>
    return 0;
    80001afc:	4481                	li	s1,0
    80001afe:	b7d5                	j	80001ae2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b00:	4681                	li	a3,0
    80001b02:	4605                	li	a2,1
    80001b04:	040005b7          	lui	a1,0x4000
    80001b08:	15fd                	addi	a1,a1,-1
    80001b0a:	05b2                	slli	a1,a1,0xc
    80001b0c:	8526                	mv	a0,s1
    80001b0e:	fffff097          	auipc	ra,0xfffff
    80001b12:	772080e7          	jalr	1906(ra) # 80001280 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b16:	4581                	li	a1,0
    80001b18:	8526                	mv	a0,s1
    80001b1a:	00000097          	auipc	ra,0x0
    80001b1e:	a2e080e7          	jalr	-1490(ra) # 80001548 <uvmfree>
    return 0;
    80001b22:	4481                	li	s1,0
    80001b24:	bf7d                	j	80001ae2 <proc_pagetable+0x58>

0000000080001b26 <proc_freepagetable>:
{
    80001b26:	1101                	addi	sp,sp,-32
    80001b28:	ec06                	sd	ra,24(sp)
    80001b2a:	e822                	sd	s0,16(sp)
    80001b2c:	e426                	sd	s1,8(sp)
    80001b2e:	e04a                	sd	s2,0(sp)
    80001b30:	1000                	addi	s0,sp,32
    80001b32:	84aa                	mv	s1,a0
    80001b34:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b36:	4681                	li	a3,0
    80001b38:	4605                	li	a2,1
    80001b3a:	040005b7          	lui	a1,0x4000
    80001b3e:	15fd                	addi	a1,a1,-1
    80001b40:	05b2                	slli	a1,a1,0xc
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	73e080e7          	jalr	1854(ra) # 80001280 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b4a:	4681                	li	a3,0
    80001b4c:	4605                	li	a2,1
    80001b4e:	020005b7          	lui	a1,0x2000
    80001b52:	15fd                	addi	a1,a1,-1
    80001b54:	05b6                	slli	a1,a1,0xd
    80001b56:	8526                	mv	a0,s1
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	728080e7          	jalr	1832(ra) # 80001280 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b60:	85ca                	mv	a1,s2
    80001b62:	8526                	mv	a0,s1
    80001b64:	00000097          	auipc	ra,0x0
    80001b68:	9e4080e7          	jalr	-1564(ra) # 80001548 <uvmfree>
}
    80001b6c:	60e2                	ld	ra,24(sp)
    80001b6e:	6442                	ld	s0,16(sp)
    80001b70:	64a2                	ld	s1,8(sp)
    80001b72:	6902                	ld	s2,0(sp)
    80001b74:	6105                	addi	sp,sp,32
    80001b76:	8082                	ret

0000000080001b78 <freeproc>:
{
    80001b78:	1101                	addi	sp,sp,-32
    80001b7a:	ec06                	sd	ra,24(sp)
    80001b7c:	e822                	sd	s0,16(sp)
    80001b7e:	e426                	sd	s1,8(sp)
    80001b80:	1000                	addi	s0,sp,32
    80001b82:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b84:	6d28                	ld	a0,88(a0)
    80001b86:	c509                	beqz	a0,80001b90 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b88:	fffff097          	auipc	ra,0xfffff
    80001b8c:	e76080e7          	jalr	-394(ra) # 800009fe <kfree>
  p->trapframe = 0;
    80001b90:	0404bc23          	sd	zero,88(s1)
  if (p->cpy_trapframe)
    80001b94:	1804b503          	ld	a0,384(s1)
    80001b98:	c509                	beqz	a0,80001ba2 <freeproc+0x2a>
    kfree((void *)p->cpy_trapframe);
    80001b9a:	fffff097          	auipc	ra,0xfffff
    80001b9e:	e64080e7          	jalr	-412(ra) # 800009fe <kfree>
  p->cpy_trapframe = 0;
    80001ba2:	1804b023          	sd	zero,384(s1)
  if (p->pagetable)
    80001ba6:	68a8                	ld	a0,80(s1)
    80001ba8:	c511                	beqz	a0,80001bb4 <freeproc+0x3c>
    proc_freepagetable(p->pagetable, p->sz);
    80001baa:	64ac                	ld	a1,72(s1)
    80001bac:	00000097          	auipc	ra,0x0
    80001bb0:	f7a080e7          	jalr	-134(ra) # 80001b26 <proc_freepagetable>
  p->pagetable = 0;
    80001bb4:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bb8:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bbc:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bc0:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bc4:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bc8:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bcc:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bd0:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bd4:	0004ac23          	sw	zero,24(s1)
}
    80001bd8:	60e2                	ld	ra,24(sp)
    80001bda:	6442                	ld	s0,16(sp)
    80001bdc:	64a2                	ld	s1,8(sp)
    80001bde:	6105                	addi	sp,sp,32
    80001be0:	8082                	ret

0000000080001be2 <allocproc>:
{
    80001be2:	1101                	addi	sp,sp,-32
    80001be4:	ec06                	sd	ra,24(sp)
    80001be6:	e822                	sd	s0,16(sp)
    80001be8:	e426                	sd	s1,8(sp)
    80001bea:	e04a                	sd	s2,0(sp)
    80001bec:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bee:	0000f497          	auipc	s1,0xf
    80001bf2:	64248493          	addi	s1,s1,1602 # 80011230 <proc>
    80001bf6:	00016917          	auipc	s2,0x16
    80001bfa:	03a90913          	addi	s2,s2,58 # 80017c30 <tickslock>
    acquire(&p->lock);
    80001bfe:	8526                	mv	a0,s1
    80001c00:	fffff097          	auipc	ra,0xfffff
    80001c04:	fea080e7          	jalr	-22(ra) # 80000bea <acquire>
    if (p->state == UNUSED)
    80001c08:	4c9c                	lw	a5,24(s1)
    80001c0a:	cf81                	beqz	a5,80001c22 <allocproc+0x40>
      release(&p->lock);
    80001c0c:	8526                	mv	a0,s1
    80001c0e:	fffff097          	auipc	ra,0xfffff
    80001c12:	090080e7          	jalr	144(ra) # 80000c9e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001c16:	1a848493          	addi	s1,s1,424
    80001c1a:	ff2492e3          	bne	s1,s2,80001bfe <allocproc+0x1c>
  return 0;
    80001c1e:	4481                	li	s1,0
    80001c20:	a055                	j	80001cc4 <allocproc+0xe2>
  p->pid = allocpid();
    80001c22:	00000097          	auipc	ra,0x0
    80001c26:	e22080e7          	jalr	-478(ra) # 80001a44 <allocpid>
    80001c2a:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c2c:	4785                	li	a5,1
    80001c2e:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c30:	fffff097          	auipc	ra,0xfffff
    80001c34:	eca080e7          	jalr	-310(ra) # 80000afa <kalloc>
    80001c38:	892a                	mv	s2,a0
    80001c3a:	eca8                	sd	a0,88(s1)
    80001c3c:	c959                	beqz	a0,80001cd2 <allocproc+0xf0>
  if ((p->cpy_trapframe = (struct trapframe *)kalloc()) == 0)
    80001c3e:	fffff097          	auipc	ra,0xfffff
    80001c42:	ebc080e7          	jalr	-324(ra) # 80000afa <kalloc>
    80001c46:	892a                	mv	s2,a0
    80001c48:	18a4b023          	sd	a0,384(s1)
    80001c4c:	cd59                	beqz	a0,80001cea <allocproc+0x108>
  p->pagetable = proc_pagetable(p);
    80001c4e:	8526                	mv	a0,s1
    80001c50:	00000097          	auipc	ra,0x0
    80001c54:	e3a080e7          	jalr	-454(ra) # 80001a8a <proc_pagetable>
    80001c58:	892a                	mv	s2,a0
    80001c5a:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c5c:	c15d                	beqz	a0,80001d02 <allocproc+0x120>
  memset(&p->context, 0, sizeof(p->context));
    80001c5e:	07000613          	li	a2,112
    80001c62:	4581                	li	a1,0
    80001c64:	06048513          	addi	a0,s1,96
    80001c68:	fffff097          	auipc	ra,0xfffff
    80001c6c:	07e080e7          	jalr	126(ra) # 80000ce6 <memset>
  p->context.ra = (uint64)forkret;
    80001c70:	00000797          	auipc	a5,0x0
    80001c74:	d8e78793          	addi	a5,a5,-626 # 800019fe <forkret>
    80001c78:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c7a:	60bc                	ld	a5,64(s1)
    80001c7c:	6705                	lui	a4,0x1
    80001c7e:	97ba                	add	a5,a5,a4
    80001c80:	f4bc                	sd	a5,104(s1)
  p->strace = -1;
    80001c82:	57fd                	li	a5,-1
    80001c84:	16f4a423          	sw	a5,360(s1)
  p->sigalarm = 0;
    80001c88:	1604a623          	sw	zero,364(s1)
  p->sigalarm_interval = -1;
    80001c8c:	16f4a823          	sw	a5,368(s1)
  p->sigalarm_handler = 0;
    80001c90:	1604aa23          	sw	zero,372(s1)
  p->CPU_ticks = 0;
    80001c94:	1604ac23          	sw	zero,376(s1)
  p->rtime = 0;
    80001c98:	1804a423          	sw	zero,392(s1)
  p->etime = 0;
    80001c9c:	1804a823          	sw	zero,400(s1)
  p->ctime = ticks;
    80001ca0:	00007797          	auipc	a5,0x7
    80001ca4:	ef07a783          	lw	a5,-272(a5) # 80008b90 <ticks>
    80001ca8:	18f4a623          	sw	a5,396(s1)
  p->priority = 60;
    80001cac:	03c00793          	li	a5,60
    80001cb0:	18f4aa23          	sw	a5,404(s1)
  p->num_schd = 0;
    80001cb4:	1804ac23          	sw	zero,408(s1)
  p->time_sleep = 0;
    80001cb8:	1804ae23          	sw	zero,412(s1)
  p->time_run = 0;
    80001cbc:	1a04a023          	sw	zero,416(s1)
  p->time_start = 0;
    80001cc0:	1a04a223          	sw	zero,420(s1)
}
    80001cc4:	8526                	mv	a0,s1
    80001cc6:	60e2                	ld	ra,24(sp)
    80001cc8:	6442                	ld	s0,16(sp)
    80001cca:	64a2                	ld	s1,8(sp)
    80001ccc:	6902                	ld	s2,0(sp)
    80001cce:	6105                	addi	sp,sp,32
    80001cd0:	8082                	ret
    freeproc(p);
    80001cd2:	8526                	mv	a0,s1
    80001cd4:	00000097          	auipc	ra,0x0
    80001cd8:	ea4080e7          	jalr	-348(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001cdc:	8526                	mv	a0,s1
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	fc0080e7          	jalr	-64(ra) # 80000c9e <release>
    return 0;
    80001ce6:	84ca                	mv	s1,s2
    80001ce8:	bff1                	j	80001cc4 <allocproc+0xe2>
    freeproc(p);
    80001cea:	8526                	mv	a0,s1
    80001cec:	00000097          	auipc	ra,0x0
    80001cf0:	e8c080e7          	jalr	-372(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001cf4:	8526                	mv	a0,s1
    80001cf6:	fffff097          	auipc	ra,0xfffff
    80001cfa:	fa8080e7          	jalr	-88(ra) # 80000c9e <release>
    return 0;
    80001cfe:	84ca                	mv	s1,s2
    80001d00:	b7d1                	j	80001cc4 <allocproc+0xe2>
    freeproc(p);
    80001d02:	8526                	mv	a0,s1
    80001d04:	00000097          	auipc	ra,0x0
    80001d08:	e74080e7          	jalr	-396(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001d0c:	8526                	mv	a0,s1
    80001d0e:	fffff097          	auipc	ra,0xfffff
    80001d12:	f90080e7          	jalr	-112(ra) # 80000c9e <release>
    return 0;
    80001d16:	84ca                	mv	s1,s2
    80001d18:	b775                	j	80001cc4 <allocproc+0xe2>

0000000080001d1a <userinit>:
{
    80001d1a:	1101                	addi	sp,sp,-32
    80001d1c:	ec06                	sd	ra,24(sp)
    80001d1e:	e822                	sd	s0,16(sp)
    80001d20:	e426                	sd	s1,8(sp)
    80001d22:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d24:	00000097          	auipc	ra,0x0
    80001d28:	ebe080e7          	jalr	-322(ra) # 80001be2 <allocproc>
    80001d2c:	84aa                	mv	s1,a0
  initproc = p;
    80001d2e:	00007797          	auipc	a5,0x7
    80001d32:	e4a7bd23          	sd	a0,-422(a5) # 80008b88 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001d36:	03400613          	li	a2,52
    80001d3a:	00007597          	auipc	a1,0x7
    80001d3e:	c7658593          	addi	a1,a1,-906 # 800089b0 <initcode>
    80001d42:	6928                	ld	a0,80(a0)
    80001d44:	fffff097          	auipc	ra,0xfffff
    80001d48:	62e080e7          	jalr	1582(ra) # 80001372 <uvmfirst>
  p->sz = PGSIZE;
    80001d4c:	6785                	lui	a5,0x1
    80001d4e:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001d50:	6cb8                	ld	a4,88(s1)
    80001d52:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001d56:	6cb8                	ld	a4,88(s1)
    80001d58:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d5a:	4641                	li	a2,16
    80001d5c:	00006597          	auipc	a1,0x6
    80001d60:	4a458593          	addi	a1,a1,1188 # 80008200 <digits+0x1c0>
    80001d64:	15848513          	addi	a0,s1,344
    80001d68:	fffff097          	auipc	ra,0xfffff
    80001d6c:	0d0080e7          	jalr	208(ra) # 80000e38 <safestrcpy>
  p->cwd = namei("/");
    80001d70:	00006517          	auipc	a0,0x6
    80001d74:	4a050513          	addi	a0,a0,1184 # 80008210 <digits+0x1d0>
    80001d78:	00003097          	auipc	ra,0x3
    80001d7c:	802080e7          	jalr	-2046(ra) # 8000457a <namei>
    80001d80:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d84:	478d                	li	a5,3
    80001d86:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d88:	8526                	mv	a0,s1
    80001d8a:	fffff097          	auipc	ra,0xfffff
    80001d8e:	f14080e7          	jalr	-236(ra) # 80000c9e <release>
}
    80001d92:	60e2                	ld	ra,24(sp)
    80001d94:	6442                	ld	s0,16(sp)
    80001d96:	64a2                	ld	s1,8(sp)
    80001d98:	6105                	addi	sp,sp,32
    80001d9a:	8082                	ret

0000000080001d9c <growproc>:
{
    80001d9c:	1101                	addi	sp,sp,-32
    80001d9e:	ec06                	sd	ra,24(sp)
    80001da0:	e822                	sd	s0,16(sp)
    80001da2:	e426                	sd	s1,8(sp)
    80001da4:	e04a                	sd	s2,0(sp)
    80001da6:	1000                	addi	s0,sp,32
    80001da8:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001daa:	00000097          	auipc	ra,0x0
    80001dae:	c1c080e7          	jalr	-996(ra) # 800019c6 <myproc>
    80001db2:	84aa                	mv	s1,a0
  sz = p->sz;
    80001db4:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001db6:	01204c63          	bgtz	s2,80001dce <growproc+0x32>
  else if (n < 0)
    80001dba:	02094663          	bltz	s2,80001de6 <growproc+0x4a>
  p->sz = sz;
    80001dbe:	e4ac                	sd	a1,72(s1)
  return 0;
    80001dc0:	4501                	li	a0,0
}
    80001dc2:	60e2                	ld	ra,24(sp)
    80001dc4:	6442                	ld	s0,16(sp)
    80001dc6:	64a2                	ld	s1,8(sp)
    80001dc8:	6902                	ld	s2,0(sp)
    80001dca:	6105                	addi	sp,sp,32
    80001dcc:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001dce:	4691                	li	a3,4
    80001dd0:	00b90633          	add	a2,s2,a1
    80001dd4:	6928                	ld	a0,80(a0)
    80001dd6:	fffff097          	auipc	ra,0xfffff
    80001dda:	656080e7          	jalr	1622(ra) # 8000142c <uvmalloc>
    80001dde:	85aa                	mv	a1,a0
    80001de0:	fd79                	bnez	a0,80001dbe <growproc+0x22>
      return -1;
    80001de2:	557d                	li	a0,-1
    80001de4:	bff9                	j	80001dc2 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001de6:	00b90633          	add	a2,s2,a1
    80001dea:	6928                	ld	a0,80(a0)
    80001dec:	fffff097          	auipc	ra,0xfffff
    80001df0:	5f8080e7          	jalr	1528(ra) # 800013e4 <uvmdealloc>
    80001df4:	85aa                	mv	a1,a0
    80001df6:	b7e1                	j	80001dbe <growproc+0x22>

0000000080001df8 <fork>:
{
    80001df8:	7179                	addi	sp,sp,-48
    80001dfa:	f406                	sd	ra,40(sp)
    80001dfc:	f022                	sd	s0,32(sp)
    80001dfe:	ec26                	sd	s1,24(sp)
    80001e00:	e84a                	sd	s2,16(sp)
    80001e02:	e44e                	sd	s3,8(sp)
    80001e04:	e052                	sd	s4,0(sp)
    80001e06:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e08:	00000097          	auipc	ra,0x0
    80001e0c:	bbe080e7          	jalr	-1090(ra) # 800019c6 <myproc>
    80001e10:	892a                	mv	s2,a0
  if ((np = allocproc()) == 0)
    80001e12:	00000097          	auipc	ra,0x0
    80001e16:	dd0080e7          	jalr	-560(ra) # 80001be2 <allocproc>
    80001e1a:	10050b63          	beqz	a0,80001f30 <fork+0x138>
    80001e1e:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001e20:	04893603          	ld	a2,72(s2)
    80001e24:	692c                	ld	a1,80(a0)
    80001e26:	05093503          	ld	a0,80(s2)
    80001e2a:	fffff097          	auipc	ra,0xfffff
    80001e2e:	756080e7          	jalr	1878(ra) # 80001580 <uvmcopy>
    80001e32:	04054663          	bltz	a0,80001e7e <fork+0x86>
  np->sz = p->sz;
    80001e36:	04893783          	ld	a5,72(s2)
    80001e3a:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e3e:	05893683          	ld	a3,88(s2)
    80001e42:	87b6                	mv	a5,a3
    80001e44:	0589b703          	ld	a4,88(s3)
    80001e48:	12068693          	addi	a3,a3,288
    80001e4c:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e50:	6788                	ld	a0,8(a5)
    80001e52:	6b8c                	ld	a1,16(a5)
    80001e54:	6f90                	ld	a2,24(a5)
    80001e56:	01073023          	sd	a6,0(a4)
    80001e5a:	e708                	sd	a0,8(a4)
    80001e5c:	eb0c                	sd	a1,16(a4)
    80001e5e:	ef10                	sd	a2,24(a4)
    80001e60:	02078793          	addi	a5,a5,32
    80001e64:	02070713          	addi	a4,a4,32
    80001e68:	fed792e3          	bne	a5,a3,80001e4c <fork+0x54>
  np->trapframe->a0 = 0;
    80001e6c:	0589b783          	ld	a5,88(s3)
    80001e70:	0607b823          	sd	zero,112(a5)
    80001e74:	0d000493          	li	s1,208
  for (i = 0; i < NOFILE; i++)
    80001e78:	15000a13          	li	s4,336
    80001e7c:	a03d                	j	80001eaa <fork+0xb2>
    freeproc(np);
    80001e7e:	854e                	mv	a0,s3
    80001e80:	00000097          	auipc	ra,0x0
    80001e84:	cf8080e7          	jalr	-776(ra) # 80001b78 <freeproc>
    release(&np->lock);
    80001e88:	854e                	mv	a0,s3
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	e14080e7          	jalr	-492(ra) # 80000c9e <release>
    return -1;
    80001e92:	5a7d                	li	s4,-1
    80001e94:	a069                	j	80001f1e <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e96:	00003097          	auipc	ra,0x3
    80001e9a:	d7a080e7          	jalr	-646(ra) # 80004c10 <filedup>
    80001e9e:	009987b3          	add	a5,s3,s1
    80001ea2:	e388                	sd	a0,0(a5)
  for (i = 0; i < NOFILE; i++)
    80001ea4:	04a1                	addi	s1,s1,8
    80001ea6:	01448763          	beq	s1,s4,80001eb4 <fork+0xbc>
    if (p->ofile[i])
    80001eaa:	009907b3          	add	a5,s2,s1
    80001eae:	6388                	ld	a0,0(a5)
    80001eb0:	f17d                	bnez	a0,80001e96 <fork+0x9e>
    80001eb2:	bfcd                	j	80001ea4 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001eb4:	15093503          	ld	a0,336(s2)
    80001eb8:	00002097          	auipc	ra,0x2
    80001ebc:	ede080e7          	jalr	-290(ra) # 80003d96 <idup>
    80001ec0:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ec4:	4641                	li	a2,16
    80001ec6:	15890593          	addi	a1,s2,344
    80001eca:	15898513          	addi	a0,s3,344
    80001ece:	fffff097          	auipc	ra,0xfffff
    80001ed2:	f6a080e7          	jalr	-150(ra) # 80000e38 <safestrcpy>
  pid = np->pid;
    80001ed6:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001eda:	854e                	mv	a0,s3
    80001edc:	fffff097          	auipc	ra,0xfffff
    80001ee0:	dc2080e7          	jalr	-574(ra) # 80000c9e <release>
  acquire(&wait_lock);
    80001ee4:	0000f497          	auipc	s1,0xf
    80001ee8:	f3448493          	addi	s1,s1,-204 # 80010e18 <wait_lock>
    80001eec:	8526                	mv	a0,s1
    80001eee:	fffff097          	auipc	ra,0xfffff
    80001ef2:	cfc080e7          	jalr	-772(ra) # 80000bea <acquire>
  np->parent = p;
    80001ef6:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001efa:	8526                	mv	a0,s1
    80001efc:	fffff097          	auipc	ra,0xfffff
    80001f00:	da2080e7          	jalr	-606(ra) # 80000c9e <release>
  acquire(&np->lock);
    80001f04:	854e                	mv	a0,s3
    80001f06:	fffff097          	auipc	ra,0xfffff
    80001f0a:	ce4080e7          	jalr	-796(ra) # 80000bea <acquire>
  np->state = RUNNABLE;
    80001f0e:	478d                	li	a5,3
    80001f10:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f14:	854e                	mv	a0,s3
    80001f16:	fffff097          	auipc	ra,0xfffff
    80001f1a:	d88080e7          	jalr	-632(ra) # 80000c9e <release>
}
    80001f1e:	8552                	mv	a0,s4
    80001f20:	70a2                	ld	ra,40(sp)
    80001f22:	7402                	ld	s0,32(sp)
    80001f24:	64e2                	ld	s1,24(sp)
    80001f26:	6942                	ld	s2,16(sp)
    80001f28:	69a2                	ld	s3,8(sp)
    80001f2a:	6a02                	ld	s4,0(sp)
    80001f2c:	6145                	addi	sp,sp,48
    80001f2e:	8082                	ret
    return -1;
    80001f30:	5a7d                	li	s4,-1
    80001f32:	b7f5                	j	80001f1e <fork+0x126>

0000000080001f34 <update_time>:
{
    80001f34:	7179                	addi	sp,sp,-48
    80001f36:	f406                	sd	ra,40(sp)
    80001f38:	f022                	sd	s0,32(sp)
    80001f3a:	ec26                	sd	s1,24(sp)
    80001f3c:	e84a                	sd	s2,16(sp)
    80001f3e:	e44e                	sd	s3,8(sp)
    80001f40:	e052                	sd	s4,0(sp)
    80001f42:	1800                	addi	s0,sp,48
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    80001f44:	0000f497          	auipc	s1,0xf
    80001f48:	2ec48493          	addi	s1,s1,748 # 80011230 <proc>
    if (p->state == SLEEPING)
    80001f4c:	4989                	li	s3,2
    if (p->state == RUNNING)
    80001f4e:	4a11                	li	s4,4
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    80001f50:	00016917          	auipc	s2,0x16
    80001f54:	ce090913          	addi	s2,s2,-800 # 80017c30 <tickslock>
    80001f58:	a839                	j	80001f76 <update_time+0x42>
      p->time_sleep++;
    80001f5a:	19c4a783          	lw	a5,412(s1)
    80001f5e:	2785                	addiw	a5,a5,1
    80001f60:	18f4ae23          	sw	a5,412(s1)
    release(&p->lock);
    80001f64:	8526                	mv	a0,s1
    80001f66:	fffff097          	auipc	ra,0xfffff
    80001f6a:	d38080e7          	jalr	-712(ra) # 80000c9e <release>
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    80001f6e:	1a848493          	addi	s1,s1,424
    80001f72:	03248763          	beq	s1,s2,80001fa0 <update_time+0x6c>
    acquire(&p->lock);
    80001f76:	8526                	mv	a0,s1
    80001f78:	fffff097          	auipc	ra,0xfffff
    80001f7c:	c72080e7          	jalr	-910(ra) # 80000bea <acquire>
    if (p->state == RUNNABLE)
    80001f80:	4c9c                	lw	a5,24(s1)
    if (p->state == SLEEPING)
    80001f82:	fd378ce3          	beq	a5,s3,80001f5a <update_time+0x26>
    if (p->state == RUNNING)
    80001f86:	fd479fe3          	bne	a5,s4,80001f64 <update_time+0x30>
      p->rtime++;
    80001f8a:	1884a783          	lw	a5,392(s1)
    80001f8e:	2785                	addiw	a5,a5,1
    80001f90:	18f4a423          	sw	a5,392(s1)
      p->time_run++;
    80001f94:	1a04a783          	lw	a5,416(s1)
    80001f98:	2785                	addiw	a5,a5,1
    80001f9a:	1af4a023          	sw	a5,416(s1)
    80001f9e:	b7d9                	j	80001f64 <update_time+0x30>
}
    80001fa0:	70a2                	ld	ra,40(sp)
    80001fa2:	7402                	ld	s0,32(sp)
    80001fa4:	64e2                	ld	s1,24(sp)
    80001fa6:	6942                	ld	s2,16(sp)
    80001fa8:	69a2                	ld	s3,8(sp)
    80001faa:	6a02                	ld	s4,0(sp)
    80001fac:	6145                	addi	sp,sp,48
    80001fae:	8082                	ret

0000000080001fb0 <do_rand>:
{
    80001fb0:	1141                	addi	sp,sp,-16
    80001fb2:	e422                	sd	s0,8(sp)
    80001fb4:	0800                	addi	s0,sp,16
  x = (*ctx % 0x7ffffffe) + 1;
    80001fb6:	611c                	ld	a5,0(a0)
    80001fb8:	80000737          	lui	a4,0x80000
    80001fbc:	ffe74713          	xori	a4,a4,-2
    80001fc0:	02e7f7b3          	remu	a5,a5,a4
    80001fc4:	0785                	addi	a5,a5,1
  lo = x % 127773;
    80001fc6:	66fd                	lui	a3,0x1f
    80001fc8:	31d68693          	addi	a3,a3,797 # 1f31d <_entry-0x7ffe0ce3>
    80001fcc:	02d7e733          	rem	a4,a5,a3
  x = 16807 * lo - 2836 * hi;
    80001fd0:	6611                	lui	a2,0x4
    80001fd2:	1a760613          	addi	a2,a2,423 # 41a7 <_entry-0x7fffbe59>
    80001fd6:	02c70733          	mul	a4,a4,a2
  hi = x / 127773;
    80001fda:	02d7c7b3          	div	a5,a5,a3
  x = 16807 * lo - 2836 * hi;
    80001fde:	76fd                	lui	a3,0xfffff
    80001fe0:	4ec68693          	addi	a3,a3,1260 # fffffffffffff4ec <end+0xffffffff7ffdc4dc>
    80001fe4:	02d787b3          	mul	a5,a5,a3
    80001fe8:	97ba                	add	a5,a5,a4
  if (x < 0)
    80001fea:	0007c963          	bltz	a5,80001ffc <do_rand+0x4c>
  x--;
    80001fee:	17fd                	addi	a5,a5,-1
  *ctx = x;
    80001ff0:	e11c                	sd	a5,0(a0)
}
    80001ff2:	0007851b          	sext.w	a0,a5
    80001ff6:	6422                	ld	s0,8(sp)
    80001ff8:	0141                	addi	sp,sp,16
    80001ffa:	8082                	ret
    x += 0x7fffffff;
    80001ffc:	80000737          	lui	a4,0x80000
    80002000:	fff74713          	not	a4,a4
    80002004:	97ba                	add	a5,a5,a4
    80002006:	b7e5                	j	80001fee <do_rand+0x3e>

0000000080002008 <rand>:
{
    80002008:	1141                	addi	sp,sp,-16
    8000200a:	e406                	sd	ra,8(sp)
    8000200c:	e022                	sd	s0,0(sp)
    8000200e:	0800                	addi	s0,sp,16
  return (do_rand(&rand_next));
    80002010:	00007517          	auipc	a0,0x7
    80002014:	98850513          	addi	a0,a0,-1656 # 80008998 <rand_next>
    80002018:	00000097          	auipc	ra,0x0
    8000201c:	f98080e7          	jalr	-104(ra) # 80001fb0 <do_rand>
}
    80002020:	60a2                	ld	ra,8(sp)
    80002022:	6402                	ld	s0,0(sp)
    80002024:	0141                	addi	sp,sp,16
    80002026:	8082                	ret

0000000080002028 <settickets>:
{
    80002028:	1141                	addi	sp,sp,-16
    8000202a:	e422                	sd	s0,8(sp)
    8000202c:	0800                	addi	s0,sp,16
}
    8000202e:	6422                	ld	s0,8(sp)
    80002030:	0141                	addi	sp,sp,16
    80002032:	8082                	ret

0000000080002034 <scheduler>:
{
    80002034:	7119                	addi	sp,sp,-128
    80002036:	fc86                	sd	ra,120(sp)
    80002038:	f8a2                	sd	s0,112(sp)
    8000203a:	f4a6                	sd	s1,104(sp)
    8000203c:	f0ca                	sd	s2,96(sp)
    8000203e:	ecce                	sd	s3,88(sp)
    80002040:	e8d2                	sd	s4,80(sp)
    80002042:	e4d6                	sd	s5,72(sp)
    80002044:	e0da                	sd	s6,64(sp)
    80002046:	fc5e                	sd	s7,56(sp)
    80002048:	f862                	sd	s8,48(sp)
    8000204a:	f466                	sd	s9,40(sp)
    8000204c:	f06a                	sd	s10,32(sp)
    8000204e:	ec6e                	sd	s11,24(sp)
    80002050:	0100                	addi	s0,sp,128
    80002052:	8792                	mv	a5,tp
  int id = r_tp();
    80002054:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002056:	00779693          	slli	a3,a5,0x7
    8000205a:	0000f717          	auipc	a4,0xf
    8000205e:	da670713          	addi	a4,a4,-602 # 80010e00 <pid_lock>
    80002062:	9736                	add	a4,a4,a3
    80002064:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p_priority->context);
    80002068:	0000f717          	auipc	a4,0xf
    8000206c:	dd070713          	addi	a4,a4,-560 # 80010e38 <cpus+0x8>
    80002070:	9736                	add	a4,a4,a3
    80002072:	f8e43423          	sd	a4,-120(s0)
    for (struct proc *p = proc; p < &proc[NPROC]; p++)
    80002076:	00016a97          	auipc	s5,0x16
    8000207a:	bbaa8a93          	addi	s5,s5,-1094 # 80017c30 <tickslock>
        int niceness = 5;
    8000207e:	4c15                	li	s8,5
    80002080:	06400d13          	li	s10,100
        c->proc = p_priority;
    80002084:	0000f717          	auipc	a4,0xf
    80002088:	d7c70713          	addi	a4,a4,-644 # 80010e00 <pid_lock>
    8000208c:	00d707b3          	add	a5,a4,a3
    80002090:	f8f43023          	sd	a5,-128(s0)
    80002094:	a20d                	j	800021b6 <scheduler+0x182>
            release(&p_priority->lock);
    80002096:	855a                	mv	a0,s6
    80002098:	fffff097          	auipc	ra,0xfffff
    8000209c:	c06080e7          	jalr	-1018(ra) # 80000c9e <release>
            max_dynamic_priority = dynamic_priority;
    800020a0:	8bca                	mv	s7,s2
            continue;
    800020a2:	aa3d                	j	800021e0 <scheduler+0x1ac>
            if (p->num_schd > p_priority->num_schd)
    800020a4:	198b2783          	lw	a5,408(s6)
    800020a8:	02c7c063          	blt	a5,a2,800020c8 <scheduler+0x94>
            else if (p->num_schd == p_priority->num_schd)
    800020ac:	08f61e63          	bne	a2,a5,80002148 <scheduler+0x114>
              if (p->time_start < p_priority->time_start)
    800020b0:	1a49a703          	lw	a4,420(s3)
    800020b4:	1a4b2783          	lw	a5,420(s6)
    800020b8:	08f75863          	bge	a4,a5,80002148 <scheduler+0x114>
                release(&p_priority->lock);
    800020bc:	855a                	mv	a0,s6
    800020be:	fffff097          	auipc	ra,0xfffff
    800020c2:	be0080e7          	jalr	-1056(ra) # 80000c9e <release>
                continue;
    800020c6:	aa29                	j	800021e0 <scheduler+0x1ac>
              release(&p_priority->lock);
    800020c8:	855a                	mv	a0,s6
    800020ca:	fffff097          	auipc	ra,0xfffff
    800020ce:	bd4080e7          	jalr	-1068(ra) # 80000c9e <release>
              continue;
    800020d2:	a239                	j	800021e0 <scheduler+0x1ac>
      release(&p->lock);
    800020d4:	8526                	mv	a0,s1
    800020d6:	fffff097          	auipc	ra,0xfffff
    800020da:	bc8080e7          	jalr	-1080(ra) # 80000c9e <release>
    for (struct proc *p = proc; p < &proc[NPROC]; p++)
    800020de:	1a848793          	addi	a5,s1,424
    800020e2:	0d57fe63          	bgeu	a5,s5,800021be <scheduler+0x18a>
    800020e6:	1a848493          	addi	s1,s1,424
    800020ea:	89a6                	mv	s3,s1
      acquire(&p->lock);
    800020ec:	8526                	mv	a0,s1
    800020ee:	fffff097          	auipc	ra,0xfffff
    800020f2:	afc080e7          	jalr	-1284(ra) # 80000bea <acquire>
      if (p->state == RUNNABLE)
    800020f6:	4c9c                	lw	a5,24(s1)
    800020f8:	fd479ee3          	bne	a5,s4,800020d4 <scheduler+0xa0>
        int dynamic_priority = p->priority + 5;
    800020fc:	1944a783          	lw	a5,404(s1)
    80002100:	2795                	addiw	a5,a5,5
        if (p->num_schd != 0)
    80002102:	1984a603          	lw	a2,408(s1)
        int niceness = 5;
    80002106:	8762                	mv	a4,s8
        if (p->num_schd != 0)
    80002108:	ce09                	beqz	a2,80002122 <scheduler+0xee>
          niceness = (p->time_sleep) / (p->time_run + p->time_sleep);
    8000210a:	19c4a703          	lw	a4,412(s1)
    8000210e:	1a04a683          	lw	a3,416(s1)
    80002112:	9eb9                	addw	a3,a3,a4
    80002114:	02d746bb          	divw	a3,a4,a3
          niceness *= 10;
    80002118:	0026971b          	slliw	a4,a3,0x2
    8000211c:	9f35                	addw	a4,a4,a3
    8000211e:	0017171b          	slliw	a4,a4,0x1
        dynamic_priority -= niceness;
    80002122:	9f99                	subw	a5,a5,a4
    80002124:	0007871b          	sext.w	a4,a5
    80002128:	fff74713          	not	a4,a4
    8000212c:	977d                	srai	a4,a4,0x3f
    8000212e:	8ff9                	and	a5,a5,a4
    80002130:	893e                	mv	s2,a5
    80002132:	2781                	sext.w	a5,a5
    80002134:	00fcd363          	bge	s9,a5,8000213a <scheduler+0x106>
    80002138:	896a                	mv	s2,s10
    8000213a:	2901                	sext.w	s2,s2
        if (p_priority != 0)
    8000213c:	0a0b0163          	beqz	s6,800021de <scheduler+0x1aa>
          if (max_dynamic_priority > dynamic_priority)
    80002140:	f5794be3          	blt	s2,s7,80002096 <scheduler+0x62>
          else if (max_dynamic_priority == dynamic_priority)
    80002144:	f77900e3          	beq	s2,s7,800020a4 <scheduler+0x70>
      release(&p->lock);
    80002148:	854e                	mv	a0,s3
    8000214a:	fffff097          	auipc	ra,0xfffff
    8000214e:	b54080e7          	jalr	-1196(ra) # 80000c9e <release>
    for (struct proc *p = proc; p < &proc[NPROC]; p++)
    80002152:	1a848793          	addi	a5,s1,424
    80002156:	f957e8e3          	bltu	a5,s5,800020e6 <scheduler+0xb2>
    8000215a:	89da                	mv	s3,s6
      if (p_priority->state == RUNNABLE)
    8000215c:	0189a703          	lw	a4,24(s3)
    80002160:	478d                	li	a5,3
    80002162:	04f71563          	bne	a4,a5,800021ac <scheduler+0x178>
        p_priority->state = RUNNING;
    80002166:	4791                	li	a5,4
    80002168:	00f9ac23          	sw	a5,24(s3)
        p_priority->num_schd++;
    8000216c:	1989a783          	lw	a5,408(s3)
    80002170:	2785                	addiw	a5,a5,1
    80002172:	18f9ac23          	sw	a5,408(s3)
        p_priority->time_sleep = 0;
    80002176:	1809ae23          	sw	zero,412(s3)
        p_priority->time_run = 0;
    8000217a:	1a09a023          	sw	zero,416(s3)
        if (p_priority->time_start == 0)
    8000217e:	1a49a783          	lw	a5,420(s3)
    80002182:	e799                	bnez	a5,80002190 <scheduler+0x15c>
          p_priority->time_start = ticks;
    80002184:	00007797          	auipc	a5,0x7
    80002188:	a0c7a783          	lw	a5,-1524(a5) # 80008b90 <ticks>
    8000218c:	1af9a223          	sw	a5,420(s3)
        c->proc = p_priority;
    80002190:	f8043483          	ld	s1,-128(s0)
    80002194:	0334b823          	sd	s3,48(s1)
        swtch(&c->context, &p_priority->context);
    80002198:	06098593          	addi	a1,s3,96
    8000219c:	f8843503          	ld	a0,-120(s0)
    800021a0:	00001097          	auipc	ra,0x1
    800021a4:	8a0080e7          	jalr	-1888(ra) # 80002a40 <swtch>
        c->proc = 0;
    800021a8:	0204b823          	sd	zero,48(s1)
      release(&p_priority->lock);
    800021ac:	854e                	mv	a0,s3
    800021ae:	fffff097          	auipc	ra,0xfffff
    800021b2:	af0080e7          	jalr	-1296(ra) # 80000c9e <release>
    int max_dynamic_priority = -1;
    800021b6:	5dfd                	li	s11,-1
    800021b8:	06400c93          	li	s9,100
    800021bc:	a019                	j	800021c2 <scheduler+0x18e>
    if (p_priority != 0)
    800021be:	f80b1ee3          	bnez	s6,8000215a <scheduler+0x126>
  asm volatile("csrr %0, sstatus"
    800021c2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021c6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0"
    800021ca:	10079073          	csrw	sstatus,a5
    for (struct proc *p = proc; p < &proc[NPROC]; p++)
    800021ce:	0000f497          	auipc	s1,0xf
    800021d2:	06248493          	addi	s1,s1,98 # 80011230 <proc>
    int max_dynamic_priority = -1;
    800021d6:	8bee                	mv	s7,s11
    struct proc *p_priority = 0;
    800021d8:	4b01                	li	s6,0
      if (p->state == RUNNABLE)
    800021da:	4a0d                	li	s4,3
    800021dc:	b739                	j	800020ea <scheduler+0xb6>
          max_dynamic_priority = dynamic_priority;
    800021de:	8bca                	mv	s7,s2
    for (struct proc *p = proc; p < &proc[NPROC]; p++)
    800021e0:	1a848793          	addi	a5,s1,424
    800021e4:	f757fce3          	bgeu	a5,s5,8000215c <scheduler+0x128>
    800021e8:	8b4e                	mv	s6,s3
    800021ea:	bdf5                	j	800020e6 <scheduler+0xb2>

00000000800021ec <sched>:
{
    800021ec:	7179                	addi	sp,sp,-48
    800021ee:	f406                	sd	ra,40(sp)
    800021f0:	f022                	sd	s0,32(sp)
    800021f2:	ec26                	sd	s1,24(sp)
    800021f4:	e84a                	sd	s2,16(sp)
    800021f6:	e44e                	sd	s3,8(sp)
    800021f8:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800021fa:	fffff097          	auipc	ra,0xfffff
    800021fe:	7cc080e7          	jalr	1996(ra) # 800019c6 <myproc>
    80002202:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002204:	fffff097          	auipc	ra,0xfffff
    80002208:	96c080e7          	jalr	-1684(ra) # 80000b70 <holding>
    8000220c:	c93d                	beqz	a0,80002282 <sched+0x96>
  asm volatile("mv %0, tp"
    8000220e:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002210:	2781                	sext.w	a5,a5
    80002212:	079e                	slli	a5,a5,0x7
    80002214:	0000f717          	auipc	a4,0xf
    80002218:	bec70713          	addi	a4,a4,-1044 # 80010e00 <pid_lock>
    8000221c:	97ba                	add	a5,a5,a4
    8000221e:	0a87a703          	lw	a4,168(a5)
    80002222:	4785                	li	a5,1
    80002224:	06f71763          	bne	a4,a5,80002292 <sched+0xa6>
  if (p->state == RUNNING)
    80002228:	4c98                	lw	a4,24(s1)
    8000222a:	4791                	li	a5,4
    8000222c:	06f70b63          	beq	a4,a5,800022a2 <sched+0xb6>
  asm volatile("csrr %0, sstatus"
    80002230:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002234:	8b89                	andi	a5,a5,2
  if (intr_get())
    80002236:	efb5                	bnez	a5,800022b2 <sched+0xc6>
  asm volatile("mv %0, tp"
    80002238:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000223a:	0000f917          	auipc	s2,0xf
    8000223e:	bc690913          	addi	s2,s2,-1082 # 80010e00 <pid_lock>
    80002242:	2781                	sext.w	a5,a5
    80002244:	079e                	slli	a5,a5,0x7
    80002246:	97ca                	add	a5,a5,s2
    80002248:	0ac7a983          	lw	s3,172(a5)
    8000224c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000224e:	2781                	sext.w	a5,a5
    80002250:	079e                	slli	a5,a5,0x7
    80002252:	0000f597          	auipc	a1,0xf
    80002256:	be658593          	addi	a1,a1,-1050 # 80010e38 <cpus+0x8>
    8000225a:	95be                	add	a1,a1,a5
    8000225c:	06048513          	addi	a0,s1,96
    80002260:	00000097          	auipc	ra,0x0
    80002264:	7e0080e7          	jalr	2016(ra) # 80002a40 <swtch>
    80002268:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000226a:	2781                	sext.w	a5,a5
    8000226c:	079e                	slli	a5,a5,0x7
    8000226e:	97ca                	add	a5,a5,s2
    80002270:	0b37a623          	sw	s3,172(a5)
}
    80002274:	70a2                	ld	ra,40(sp)
    80002276:	7402                	ld	s0,32(sp)
    80002278:	64e2                	ld	s1,24(sp)
    8000227a:	6942                	ld	s2,16(sp)
    8000227c:	69a2                	ld	s3,8(sp)
    8000227e:	6145                	addi	sp,sp,48
    80002280:	8082                	ret
    panic("sched p->lock");
    80002282:	00006517          	auipc	a0,0x6
    80002286:	f9650513          	addi	a0,a0,-106 # 80008218 <digits+0x1d8>
    8000228a:	ffffe097          	auipc	ra,0xffffe
    8000228e:	2ba080e7          	jalr	698(ra) # 80000544 <panic>
    panic("sched locks");
    80002292:	00006517          	auipc	a0,0x6
    80002296:	f9650513          	addi	a0,a0,-106 # 80008228 <digits+0x1e8>
    8000229a:	ffffe097          	auipc	ra,0xffffe
    8000229e:	2aa080e7          	jalr	682(ra) # 80000544 <panic>
    panic("sched running");
    800022a2:	00006517          	auipc	a0,0x6
    800022a6:	f9650513          	addi	a0,a0,-106 # 80008238 <digits+0x1f8>
    800022aa:	ffffe097          	auipc	ra,0xffffe
    800022ae:	29a080e7          	jalr	666(ra) # 80000544 <panic>
    panic("sched interruptible");
    800022b2:	00006517          	auipc	a0,0x6
    800022b6:	f9650513          	addi	a0,a0,-106 # 80008248 <digits+0x208>
    800022ba:	ffffe097          	auipc	ra,0xffffe
    800022be:	28a080e7          	jalr	650(ra) # 80000544 <panic>

00000000800022c2 <yield>:
{
    800022c2:	1101                	addi	sp,sp,-32
    800022c4:	ec06                	sd	ra,24(sp)
    800022c6:	e822                	sd	s0,16(sp)
    800022c8:	e426                	sd	s1,8(sp)
    800022ca:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800022cc:	fffff097          	auipc	ra,0xfffff
    800022d0:	6fa080e7          	jalr	1786(ra) # 800019c6 <myproc>
    800022d4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022d6:	fffff097          	auipc	ra,0xfffff
    800022da:	914080e7          	jalr	-1772(ra) # 80000bea <acquire>
  p->state = RUNNABLE;
    800022de:	478d                	li	a5,3
    800022e0:	cc9c                	sw	a5,24(s1)
  sched();
    800022e2:	00000097          	auipc	ra,0x0
    800022e6:	f0a080e7          	jalr	-246(ra) # 800021ec <sched>
  release(&p->lock);
    800022ea:	8526                	mv	a0,s1
    800022ec:	fffff097          	auipc	ra,0xfffff
    800022f0:	9b2080e7          	jalr	-1614(ra) # 80000c9e <release>
}
    800022f4:	60e2                	ld	ra,24(sp)
    800022f6:	6442                	ld	s0,16(sp)
    800022f8:	64a2                	ld	s1,8(sp)
    800022fa:	6105                	addi	sp,sp,32
    800022fc:	8082                	ret

00000000800022fe <set_priority>:
{
    800022fe:	7179                	addi	sp,sp,-48
    80002300:	f406                	sd	ra,40(sp)
    80002302:	f022                	sd	s0,32(sp)
    80002304:	ec26                	sd	s1,24(sp)
    80002306:	e84a                	sd	s2,16(sp)
    80002308:	e44e                	sd	s3,8(sp)
    8000230a:	e052                	sd	s4,0(sp)
    8000230c:	1800                	addi	s0,sp,48
    8000230e:	8a2a                	mv	s4,a0
    80002310:	892e                	mv	s2,a1
  for (p = proc; p < &proc[NPROC]; p++)
    80002312:	0000f497          	auipc	s1,0xf
    80002316:	f1e48493          	addi	s1,s1,-226 # 80011230 <proc>
    8000231a:	00016997          	auipc	s3,0x16
    8000231e:	91698993          	addi	s3,s3,-1770 # 80017c30 <tickslock>
    acquire(&p->lock);
    80002322:	8526                	mv	a0,s1
    80002324:	fffff097          	auipc	ra,0xfffff
    80002328:	8c6080e7          	jalr	-1850(ra) # 80000bea <acquire>
    if (p->pid == pid)
    8000232c:	589c                	lw	a5,48(s1)
    8000232e:	01278d63          	beq	a5,s2,80002348 <set_priority+0x4a>
    release(&p->lock);
    80002332:	8526                	mv	a0,s1
    80002334:	fffff097          	auipc	ra,0xfffff
    80002338:	96a080e7          	jalr	-1686(ra) # 80000c9e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000233c:	1a848493          	addi	s1,s1,424
    80002340:	ff3491e3          	bne	s1,s3,80002322 <set_priority+0x24>
  int priority = -1;
    80002344:	597d                	li	s2,-1
    80002346:	a015                	j	8000236a <set_priority+0x6c>
      priority = p->priority;
    80002348:	1944a903          	lw	s2,404(s1)
      p->priority = new_priority;
    8000234c:	1944aa23          	sw	s4,404(s1)
      p->time_run = 0;
    80002350:	1a04a023          	sw	zero,416(s1)
      p->time_sleep = 0;
    80002354:	1804ae23          	sw	zero,412(s1)
    release(&p->lock);
    80002358:	8526                	mv	a0,s1
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	944080e7          	jalr	-1724(ra) # 80000c9e <release>
    if (priority < p->priority)
    80002362:	1944a783          	lw	a5,404(s1)
    80002366:	00f94b63          	blt	s2,a5,8000237c <set_priority+0x7e>
}
    8000236a:	854a                	mv	a0,s2
    8000236c:	70a2                	ld	ra,40(sp)
    8000236e:	7402                	ld	s0,32(sp)
    80002370:	64e2                	ld	s1,24(sp)
    80002372:	6942                	ld	s2,16(sp)
    80002374:	69a2                	ld	s3,8(sp)
    80002376:	6a02                	ld	s4,0(sp)
    80002378:	6145                	addi	sp,sp,48
    8000237a:	8082                	ret
      yield();
    8000237c:	00000097          	auipc	ra,0x0
    80002380:	f46080e7          	jalr	-186(ra) # 800022c2 <yield>
    80002384:	b7dd                	j	8000236a <set_priority+0x6c>

0000000080002386 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002386:	7179                	addi	sp,sp,-48
    80002388:	f406                	sd	ra,40(sp)
    8000238a:	f022                	sd	s0,32(sp)
    8000238c:	ec26                	sd	s1,24(sp)
    8000238e:	e84a                	sd	s2,16(sp)
    80002390:	e44e                	sd	s3,8(sp)
    80002392:	1800                	addi	s0,sp,48
    80002394:	89aa                	mv	s3,a0
    80002396:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	62e080e7          	jalr	1582(ra) # 800019c6 <myproc>
    800023a0:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800023a2:	fffff097          	auipc	ra,0xfffff
    800023a6:	848080e7          	jalr	-1976(ra) # 80000bea <acquire>
  release(lk);
    800023aa:	854a                	mv	a0,s2
    800023ac:	fffff097          	auipc	ra,0xfffff
    800023b0:	8f2080e7          	jalr	-1806(ra) # 80000c9e <release>

  // Go to sleep.
  p->chan = chan;
    800023b4:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800023b8:	4789                	li	a5,2
    800023ba:	cc9c                	sw	a5,24(s1)

  sched();
    800023bc:	00000097          	auipc	ra,0x0
    800023c0:	e30080e7          	jalr	-464(ra) # 800021ec <sched>

  // Tidy up.
  p->chan = 0;
    800023c4:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800023c8:	8526                	mv	a0,s1
    800023ca:	fffff097          	auipc	ra,0xfffff
    800023ce:	8d4080e7          	jalr	-1836(ra) # 80000c9e <release>
  acquire(lk);
    800023d2:	854a                	mv	a0,s2
    800023d4:	fffff097          	auipc	ra,0xfffff
    800023d8:	816080e7          	jalr	-2026(ra) # 80000bea <acquire>
}
    800023dc:	70a2                	ld	ra,40(sp)
    800023de:	7402                	ld	s0,32(sp)
    800023e0:	64e2                	ld	s1,24(sp)
    800023e2:	6942                	ld	s2,16(sp)
    800023e4:	69a2                	ld	s3,8(sp)
    800023e6:	6145                	addi	sp,sp,48
    800023e8:	8082                	ret

00000000800023ea <waitx>:
{
    800023ea:	711d                	addi	sp,sp,-96
    800023ec:	ec86                	sd	ra,88(sp)
    800023ee:	e8a2                	sd	s0,80(sp)
    800023f0:	e4a6                	sd	s1,72(sp)
    800023f2:	e0ca                	sd	s2,64(sp)
    800023f4:	fc4e                	sd	s3,56(sp)
    800023f6:	f852                	sd	s4,48(sp)
    800023f8:	f456                	sd	s5,40(sp)
    800023fa:	f05a                	sd	s6,32(sp)
    800023fc:	ec5e                	sd	s7,24(sp)
    800023fe:	e862                	sd	s8,16(sp)
    80002400:	e466                	sd	s9,8(sp)
    80002402:	e06a                	sd	s10,0(sp)
    80002404:	1080                	addi	s0,sp,96
    80002406:	8b2a                	mv	s6,a0
    80002408:	8bae                	mv	s7,a1
    8000240a:	8c32                	mv	s8,a2
  struct proc *p = myproc();
    8000240c:	fffff097          	auipc	ra,0xfffff
    80002410:	5ba080e7          	jalr	1466(ra) # 800019c6 <myproc>
    80002414:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002416:	0000f517          	auipc	a0,0xf
    8000241a:	a0250513          	addi	a0,a0,-1534 # 80010e18 <wait_lock>
    8000241e:	ffffe097          	auipc	ra,0xffffe
    80002422:	7cc080e7          	jalr	1996(ra) # 80000bea <acquire>
    havekids = 0;
    80002426:	4c81                	li	s9,0
        if (np->state == ZOMBIE)
    80002428:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    8000242a:	00016997          	auipc	s3,0x16
    8000242e:	80698993          	addi	s3,s3,-2042 # 80017c30 <tickslock>
        havekids = 1;
    80002432:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002434:	0000fd17          	auipc	s10,0xf
    80002438:	9e4d0d13          	addi	s10,s10,-1564 # 80010e18 <wait_lock>
    havekids = 0;
    8000243c:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    8000243e:	0000f497          	auipc	s1,0xf
    80002442:	df248493          	addi	s1,s1,-526 # 80011230 <proc>
    80002446:	a059                	j	800024cc <waitx+0xe2>
          pid = np->pid;
    80002448:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    8000244c:	1884a703          	lw	a4,392(s1)
    80002450:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002454:	18c4a783          	lw	a5,396(s1)
    80002458:	9f3d                	addw	a4,a4,a5
    8000245a:	1904a783          	lw	a5,400(s1)
    8000245e:	9f99                	subw	a5,a5,a4
    80002460:	00fba023          	sw	a5,0(s7) # fffffffffffff000 <end+0xffffffff7ffdbff0>
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002464:	000b0e63          	beqz	s6,80002480 <waitx+0x96>
    80002468:	4691                	li	a3,4
    8000246a:	02c48613          	addi	a2,s1,44
    8000246e:	85da                	mv	a1,s6
    80002470:	05093503          	ld	a0,80(s2)
    80002474:	fffff097          	auipc	ra,0xfffff
    80002478:	210080e7          	jalr	528(ra) # 80001684 <copyout>
    8000247c:	02054563          	bltz	a0,800024a6 <waitx+0xbc>
          freeproc(np);
    80002480:	8526                	mv	a0,s1
    80002482:	fffff097          	auipc	ra,0xfffff
    80002486:	6f6080e7          	jalr	1782(ra) # 80001b78 <freeproc>
          release(&np->lock);
    8000248a:	8526                	mv	a0,s1
    8000248c:	fffff097          	auipc	ra,0xfffff
    80002490:	812080e7          	jalr	-2030(ra) # 80000c9e <release>
          release(&wait_lock);
    80002494:	0000f517          	auipc	a0,0xf
    80002498:	98450513          	addi	a0,a0,-1660 # 80010e18 <wait_lock>
    8000249c:	fffff097          	auipc	ra,0xfffff
    800024a0:	802080e7          	jalr	-2046(ra) # 80000c9e <release>
          return pid;
    800024a4:	a09d                	j	8000250a <waitx+0x120>
            release(&np->lock);
    800024a6:	8526                	mv	a0,s1
    800024a8:	ffffe097          	auipc	ra,0xffffe
    800024ac:	7f6080e7          	jalr	2038(ra) # 80000c9e <release>
            release(&wait_lock);
    800024b0:	0000f517          	auipc	a0,0xf
    800024b4:	96850513          	addi	a0,a0,-1688 # 80010e18 <wait_lock>
    800024b8:	ffffe097          	auipc	ra,0xffffe
    800024bc:	7e6080e7          	jalr	2022(ra) # 80000c9e <release>
            return -1;
    800024c0:	59fd                	li	s3,-1
    800024c2:	a0a1                	j	8000250a <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    800024c4:	1a848493          	addi	s1,s1,424
    800024c8:	03348463          	beq	s1,s3,800024f0 <waitx+0x106>
      if (np->parent == p)
    800024cc:	7c9c                	ld	a5,56(s1)
    800024ce:	ff279be3          	bne	a5,s2,800024c4 <waitx+0xda>
        acquire(&np->lock);
    800024d2:	8526                	mv	a0,s1
    800024d4:	ffffe097          	auipc	ra,0xffffe
    800024d8:	716080e7          	jalr	1814(ra) # 80000bea <acquire>
        if (np->state == ZOMBIE)
    800024dc:	4c9c                	lw	a5,24(s1)
    800024de:	f74785e3          	beq	a5,s4,80002448 <waitx+0x5e>
        release(&np->lock);
    800024e2:	8526                	mv	a0,s1
    800024e4:	ffffe097          	auipc	ra,0xffffe
    800024e8:	7ba080e7          	jalr	1978(ra) # 80000c9e <release>
        havekids = 1;
    800024ec:	8756                	mv	a4,s5
    800024ee:	bfd9                	j	800024c4 <waitx+0xda>
    if (!havekids || p->killed)
    800024f0:	c701                	beqz	a4,800024f8 <waitx+0x10e>
    800024f2:	02892783          	lw	a5,40(s2)
    800024f6:	cb8d                	beqz	a5,80002528 <waitx+0x13e>
      release(&wait_lock);
    800024f8:	0000f517          	auipc	a0,0xf
    800024fc:	92050513          	addi	a0,a0,-1760 # 80010e18 <wait_lock>
    80002500:	ffffe097          	auipc	ra,0xffffe
    80002504:	79e080e7          	jalr	1950(ra) # 80000c9e <release>
      return -1;
    80002508:	59fd                	li	s3,-1
}
    8000250a:	854e                	mv	a0,s3
    8000250c:	60e6                	ld	ra,88(sp)
    8000250e:	6446                	ld	s0,80(sp)
    80002510:	64a6                	ld	s1,72(sp)
    80002512:	6906                	ld	s2,64(sp)
    80002514:	79e2                	ld	s3,56(sp)
    80002516:	7a42                	ld	s4,48(sp)
    80002518:	7aa2                	ld	s5,40(sp)
    8000251a:	7b02                	ld	s6,32(sp)
    8000251c:	6be2                	ld	s7,24(sp)
    8000251e:	6c42                	ld	s8,16(sp)
    80002520:	6ca2                	ld	s9,8(sp)
    80002522:	6d02                	ld	s10,0(sp)
    80002524:	6125                	addi	sp,sp,96
    80002526:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002528:	85ea                	mv	a1,s10
    8000252a:	854a                	mv	a0,s2
    8000252c:	00000097          	auipc	ra,0x0
    80002530:	e5a080e7          	jalr	-422(ra) # 80002386 <sleep>
    havekids = 0;
    80002534:	b721                	j	8000243c <waitx+0x52>

0000000080002536 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002536:	7139                	addi	sp,sp,-64
    80002538:	fc06                	sd	ra,56(sp)
    8000253a:	f822                	sd	s0,48(sp)
    8000253c:	f426                	sd	s1,40(sp)
    8000253e:	f04a                	sd	s2,32(sp)
    80002540:	ec4e                	sd	s3,24(sp)
    80002542:	e852                	sd	s4,16(sp)
    80002544:	e456                	sd	s5,8(sp)
    80002546:	0080                	addi	s0,sp,64
    80002548:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000254a:	0000f497          	auipc	s1,0xf
    8000254e:	ce648493          	addi	s1,s1,-794 # 80011230 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002552:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002554:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002556:	00015917          	auipc	s2,0x15
    8000255a:	6da90913          	addi	s2,s2,1754 # 80017c30 <tickslock>
    8000255e:	a821                	j	80002576 <wakeup+0x40>
        p->state = RUNNABLE;
    80002560:	0154ac23          	sw	s5,24(s1)
#ifdef MLFQ
        push(p, p->prev_queue);
#endif
      }
      release(&p->lock);
    80002564:	8526                	mv	a0,s1
    80002566:	ffffe097          	auipc	ra,0xffffe
    8000256a:	738080e7          	jalr	1848(ra) # 80000c9e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000256e:	1a848493          	addi	s1,s1,424
    80002572:	03248463          	beq	s1,s2,8000259a <wakeup+0x64>
    if (p != myproc())
    80002576:	fffff097          	auipc	ra,0xfffff
    8000257a:	450080e7          	jalr	1104(ra) # 800019c6 <myproc>
    8000257e:	fea488e3          	beq	s1,a0,8000256e <wakeup+0x38>
      acquire(&p->lock);
    80002582:	8526                	mv	a0,s1
    80002584:	ffffe097          	auipc	ra,0xffffe
    80002588:	666080e7          	jalr	1638(ra) # 80000bea <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    8000258c:	4c9c                	lw	a5,24(s1)
    8000258e:	fd379be3          	bne	a5,s3,80002564 <wakeup+0x2e>
    80002592:	709c                	ld	a5,32(s1)
    80002594:	fd4798e3          	bne	a5,s4,80002564 <wakeup+0x2e>
    80002598:	b7e1                	j	80002560 <wakeup+0x2a>
    }
  }
}
    8000259a:	70e2                	ld	ra,56(sp)
    8000259c:	7442                	ld	s0,48(sp)
    8000259e:	74a2                	ld	s1,40(sp)
    800025a0:	7902                	ld	s2,32(sp)
    800025a2:	69e2                	ld	s3,24(sp)
    800025a4:	6a42                	ld	s4,16(sp)
    800025a6:	6aa2                	ld	s5,8(sp)
    800025a8:	6121                	addi	sp,sp,64
    800025aa:	8082                	ret

00000000800025ac <reparent>:
{
    800025ac:	7179                	addi	sp,sp,-48
    800025ae:	f406                	sd	ra,40(sp)
    800025b0:	f022                	sd	s0,32(sp)
    800025b2:	ec26                	sd	s1,24(sp)
    800025b4:	e84a                	sd	s2,16(sp)
    800025b6:	e44e                	sd	s3,8(sp)
    800025b8:	e052                	sd	s4,0(sp)
    800025ba:	1800                	addi	s0,sp,48
    800025bc:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800025be:	0000f497          	auipc	s1,0xf
    800025c2:	c7248493          	addi	s1,s1,-910 # 80011230 <proc>
      pp->parent = initproc;
    800025c6:	00006a17          	auipc	s4,0x6
    800025ca:	5c2a0a13          	addi	s4,s4,1474 # 80008b88 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800025ce:	00015997          	auipc	s3,0x15
    800025d2:	66298993          	addi	s3,s3,1634 # 80017c30 <tickslock>
    800025d6:	a029                	j	800025e0 <reparent+0x34>
    800025d8:	1a848493          	addi	s1,s1,424
    800025dc:	01348d63          	beq	s1,s3,800025f6 <reparent+0x4a>
    if (pp->parent == p)
    800025e0:	7c9c                	ld	a5,56(s1)
    800025e2:	ff279be3          	bne	a5,s2,800025d8 <reparent+0x2c>
      pp->parent = initproc;
    800025e6:	000a3503          	ld	a0,0(s4)
    800025ea:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800025ec:	00000097          	auipc	ra,0x0
    800025f0:	f4a080e7          	jalr	-182(ra) # 80002536 <wakeup>
    800025f4:	b7d5                	j	800025d8 <reparent+0x2c>
}
    800025f6:	70a2                	ld	ra,40(sp)
    800025f8:	7402                	ld	s0,32(sp)
    800025fa:	64e2                	ld	s1,24(sp)
    800025fc:	6942                	ld	s2,16(sp)
    800025fe:	69a2                	ld	s3,8(sp)
    80002600:	6a02                	ld	s4,0(sp)
    80002602:	6145                	addi	sp,sp,48
    80002604:	8082                	ret

0000000080002606 <exit>:
{
    80002606:	7179                	addi	sp,sp,-48
    80002608:	f406                	sd	ra,40(sp)
    8000260a:	f022                	sd	s0,32(sp)
    8000260c:	ec26                	sd	s1,24(sp)
    8000260e:	e84a                	sd	s2,16(sp)
    80002610:	e44e                	sd	s3,8(sp)
    80002612:	e052                	sd	s4,0(sp)
    80002614:	1800                	addi	s0,sp,48
    80002616:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002618:	fffff097          	auipc	ra,0xfffff
    8000261c:	3ae080e7          	jalr	942(ra) # 800019c6 <myproc>
    80002620:	89aa                	mv	s3,a0
  if (p == initproc)
    80002622:	00006797          	auipc	a5,0x6
    80002626:	5667b783          	ld	a5,1382(a5) # 80008b88 <initproc>
    8000262a:	0d050493          	addi	s1,a0,208
    8000262e:	15050913          	addi	s2,a0,336
    80002632:	02a79363          	bne	a5,a0,80002658 <exit+0x52>
    panic("init exiting");
    80002636:	00006517          	auipc	a0,0x6
    8000263a:	c2a50513          	addi	a0,a0,-982 # 80008260 <digits+0x220>
    8000263e:	ffffe097          	auipc	ra,0xffffe
    80002642:	f06080e7          	jalr	-250(ra) # 80000544 <panic>
      fileclose(f);
    80002646:	00002097          	auipc	ra,0x2
    8000264a:	61c080e7          	jalr	1564(ra) # 80004c62 <fileclose>
      p->ofile[fd] = 0;
    8000264e:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002652:	04a1                	addi	s1,s1,8
    80002654:	01248563          	beq	s1,s2,8000265e <exit+0x58>
    if (p->ofile[fd])
    80002658:	6088                	ld	a0,0(s1)
    8000265a:	f575                	bnez	a0,80002646 <exit+0x40>
    8000265c:	bfdd                	j	80002652 <exit+0x4c>
  begin_op();
    8000265e:	00002097          	auipc	ra,0x2
    80002662:	138080e7          	jalr	312(ra) # 80004796 <begin_op>
  iput(p->cwd);
    80002666:	1509b503          	ld	a0,336(s3)
    8000266a:	00002097          	auipc	ra,0x2
    8000266e:	924080e7          	jalr	-1756(ra) # 80003f8e <iput>
  end_op();
    80002672:	00002097          	auipc	ra,0x2
    80002676:	1a4080e7          	jalr	420(ra) # 80004816 <end_op>
  p->cwd = 0;
    8000267a:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000267e:	0000e497          	auipc	s1,0xe
    80002682:	79a48493          	addi	s1,s1,1946 # 80010e18 <wait_lock>
    80002686:	8526                	mv	a0,s1
    80002688:	ffffe097          	auipc	ra,0xffffe
    8000268c:	562080e7          	jalr	1378(ra) # 80000bea <acquire>
  reparent(p);
    80002690:	854e                	mv	a0,s3
    80002692:	00000097          	auipc	ra,0x0
    80002696:	f1a080e7          	jalr	-230(ra) # 800025ac <reparent>
  wakeup(p->parent);
    8000269a:	0389b503          	ld	a0,56(s3)
    8000269e:	00000097          	auipc	ra,0x0
    800026a2:	e98080e7          	jalr	-360(ra) # 80002536 <wakeup>
  acquire(&p->lock);
    800026a6:	854e                	mv	a0,s3
    800026a8:	ffffe097          	auipc	ra,0xffffe
    800026ac:	542080e7          	jalr	1346(ra) # 80000bea <acquire>
  p->xstate = status;
    800026b0:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800026b4:	4795                	li	a5,5
    800026b6:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800026ba:	00006797          	auipc	a5,0x6
    800026be:	4d67a783          	lw	a5,1238(a5) # 80008b90 <ticks>
    800026c2:	18f9a823          	sw	a5,400(s3)
  release(&wait_lock);
    800026c6:	8526                	mv	a0,s1
    800026c8:	ffffe097          	auipc	ra,0xffffe
    800026cc:	5d6080e7          	jalr	1494(ra) # 80000c9e <release>
  sched();
    800026d0:	00000097          	auipc	ra,0x0
    800026d4:	b1c080e7          	jalr	-1252(ra) # 800021ec <sched>
  panic("zombie exit");
    800026d8:	00006517          	auipc	a0,0x6
    800026dc:	b9850513          	addi	a0,a0,-1128 # 80008270 <digits+0x230>
    800026e0:	ffffe097          	auipc	ra,0xffffe
    800026e4:	e64080e7          	jalr	-412(ra) # 80000544 <panic>

00000000800026e8 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800026e8:	7179                	addi	sp,sp,-48
    800026ea:	f406                	sd	ra,40(sp)
    800026ec:	f022                	sd	s0,32(sp)
    800026ee:	ec26                	sd	s1,24(sp)
    800026f0:	e84a                	sd	s2,16(sp)
    800026f2:	e44e                	sd	s3,8(sp)
    800026f4:	1800                	addi	s0,sp,48
    800026f6:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800026f8:	0000f497          	auipc	s1,0xf
    800026fc:	b3848493          	addi	s1,s1,-1224 # 80011230 <proc>
    80002700:	00015997          	auipc	s3,0x15
    80002704:	53098993          	addi	s3,s3,1328 # 80017c30 <tickslock>
  {
    acquire(&p->lock);
    80002708:	8526                	mv	a0,s1
    8000270a:	ffffe097          	auipc	ra,0xffffe
    8000270e:	4e0080e7          	jalr	1248(ra) # 80000bea <acquire>
    if (p->pid == pid)
    80002712:	589c                	lw	a5,48(s1)
    80002714:	01278d63          	beq	a5,s2,8000272e <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002718:	8526                	mv	a0,s1
    8000271a:	ffffe097          	auipc	ra,0xffffe
    8000271e:	584080e7          	jalr	1412(ra) # 80000c9e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002722:	1a848493          	addi	s1,s1,424
    80002726:	ff3491e3          	bne	s1,s3,80002708 <kill+0x20>
  }
  return -1;
    8000272a:	557d                	li	a0,-1
    8000272c:	a829                	j	80002746 <kill+0x5e>
      p->killed = 1;
    8000272e:	4785                	li	a5,1
    80002730:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002732:	4c98                	lw	a4,24(s1)
    80002734:	4789                	li	a5,2
    80002736:	00f70f63          	beq	a4,a5,80002754 <kill+0x6c>
      release(&p->lock);
    8000273a:	8526                	mv	a0,s1
    8000273c:	ffffe097          	auipc	ra,0xffffe
    80002740:	562080e7          	jalr	1378(ra) # 80000c9e <release>
      return 0;
    80002744:	4501                	li	a0,0
}
    80002746:	70a2                	ld	ra,40(sp)
    80002748:	7402                	ld	s0,32(sp)
    8000274a:	64e2                	ld	s1,24(sp)
    8000274c:	6942                	ld	s2,16(sp)
    8000274e:	69a2                	ld	s3,8(sp)
    80002750:	6145                	addi	sp,sp,48
    80002752:	8082                	ret
        p->state = RUNNABLE;
    80002754:	478d                	li	a5,3
    80002756:	cc9c                	sw	a5,24(s1)
    80002758:	b7cd                	j	8000273a <kill+0x52>

000000008000275a <setkilled>:

void setkilled(struct proc *p)
{
    8000275a:	1101                	addi	sp,sp,-32
    8000275c:	ec06                	sd	ra,24(sp)
    8000275e:	e822                	sd	s0,16(sp)
    80002760:	e426                	sd	s1,8(sp)
    80002762:	1000                	addi	s0,sp,32
    80002764:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002766:	ffffe097          	auipc	ra,0xffffe
    8000276a:	484080e7          	jalr	1156(ra) # 80000bea <acquire>
  p->killed = 1;
    8000276e:	4785                	li	a5,1
    80002770:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002772:	8526                	mv	a0,s1
    80002774:	ffffe097          	auipc	ra,0xffffe
    80002778:	52a080e7          	jalr	1322(ra) # 80000c9e <release>
}
    8000277c:	60e2                	ld	ra,24(sp)
    8000277e:	6442                	ld	s0,16(sp)
    80002780:	64a2                	ld	s1,8(sp)
    80002782:	6105                	addi	sp,sp,32
    80002784:	8082                	ret

0000000080002786 <killed>:

int killed(struct proc *p)
{
    80002786:	1101                	addi	sp,sp,-32
    80002788:	ec06                	sd	ra,24(sp)
    8000278a:	e822                	sd	s0,16(sp)
    8000278c:	e426                	sd	s1,8(sp)
    8000278e:	e04a                	sd	s2,0(sp)
    80002790:	1000                	addi	s0,sp,32
    80002792:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002794:	ffffe097          	auipc	ra,0xffffe
    80002798:	456080e7          	jalr	1110(ra) # 80000bea <acquire>
  k = p->killed;
    8000279c:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800027a0:	8526                	mv	a0,s1
    800027a2:	ffffe097          	auipc	ra,0xffffe
    800027a6:	4fc080e7          	jalr	1276(ra) # 80000c9e <release>
  return k;
}
    800027aa:	854a                	mv	a0,s2
    800027ac:	60e2                	ld	ra,24(sp)
    800027ae:	6442                	ld	s0,16(sp)
    800027b0:	64a2                	ld	s1,8(sp)
    800027b2:	6902                	ld	s2,0(sp)
    800027b4:	6105                	addi	sp,sp,32
    800027b6:	8082                	ret

00000000800027b8 <wait>:
{
    800027b8:	715d                	addi	sp,sp,-80
    800027ba:	e486                	sd	ra,72(sp)
    800027bc:	e0a2                	sd	s0,64(sp)
    800027be:	fc26                	sd	s1,56(sp)
    800027c0:	f84a                	sd	s2,48(sp)
    800027c2:	f44e                	sd	s3,40(sp)
    800027c4:	f052                	sd	s4,32(sp)
    800027c6:	ec56                	sd	s5,24(sp)
    800027c8:	e85a                	sd	s6,16(sp)
    800027ca:	e45e                	sd	s7,8(sp)
    800027cc:	e062                	sd	s8,0(sp)
    800027ce:	0880                	addi	s0,sp,80
    800027d0:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800027d2:	fffff097          	auipc	ra,0xfffff
    800027d6:	1f4080e7          	jalr	500(ra) # 800019c6 <myproc>
    800027da:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800027dc:	0000e517          	auipc	a0,0xe
    800027e0:	63c50513          	addi	a0,a0,1596 # 80010e18 <wait_lock>
    800027e4:	ffffe097          	auipc	ra,0xffffe
    800027e8:	406080e7          	jalr	1030(ra) # 80000bea <acquire>
    havekids = 0;
    800027ec:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    800027ee:	4a15                	li	s4,5
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800027f0:	00015997          	auipc	s3,0x15
    800027f4:	44098993          	addi	s3,s3,1088 # 80017c30 <tickslock>
        havekids = 1;
    800027f8:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    800027fa:	0000ec17          	auipc	s8,0xe
    800027fe:	61ec0c13          	addi	s8,s8,1566 # 80010e18 <wait_lock>
    havekids = 0;
    80002802:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002804:	0000f497          	auipc	s1,0xf
    80002808:	a2c48493          	addi	s1,s1,-1492 # 80011230 <proc>
    8000280c:	a0bd                	j	8000287a <wait+0xc2>
          pid = pp->pid;
    8000280e:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002812:	000b0e63          	beqz	s6,8000282e <wait+0x76>
    80002816:	4691                	li	a3,4
    80002818:	02c48613          	addi	a2,s1,44
    8000281c:	85da                	mv	a1,s6
    8000281e:	05093503          	ld	a0,80(s2)
    80002822:	fffff097          	auipc	ra,0xfffff
    80002826:	e62080e7          	jalr	-414(ra) # 80001684 <copyout>
    8000282a:	02054563          	bltz	a0,80002854 <wait+0x9c>
          freeproc(pp);
    8000282e:	8526                	mv	a0,s1
    80002830:	fffff097          	auipc	ra,0xfffff
    80002834:	348080e7          	jalr	840(ra) # 80001b78 <freeproc>
          release(&pp->lock);
    80002838:	8526                	mv	a0,s1
    8000283a:	ffffe097          	auipc	ra,0xffffe
    8000283e:	464080e7          	jalr	1124(ra) # 80000c9e <release>
          release(&wait_lock);
    80002842:	0000e517          	auipc	a0,0xe
    80002846:	5d650513          	addi	a0,a0,1494 # 80010e18 <wait_lock>
    8000284a:	ffffe097          	auipc	ra,0xffffe
    8000284e:	454080e7          	jalr	1108(ra) # 80000c9e <release>
          return pid;
    80002852:	a0b5                	j	800028be <wait+0x106>
            release(&pp->lock);
    80002854:	8526                	mv	a0,s1
    80002856:	ffffe097          	auipc	ra,0xffffe
    8000285a:	448080e7          	jalr	1096(ra) # 80000c9e <release>
            release(&wait_lock);
    8000285e:	0000e517          	auipc	a0,0xe
    80002862:	5ba50513          	addi	a0,a0,1466 # 80010e18 <wait_lock>
    80002866:	ffffe097          	auipc	ra,0xffffe
    8000286a:	438080e7          	jalr	1080(ra) # 80000c9e <release>
            return -1;
    8000286e:	59fd                	li	s3,-1
    80002870:	a0b9                	j	800028be <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002872:	1a848493          	addi	s1,s1,424
    80002876:	03348463          	beq	s1,s3,8000289e <wait+0xe6>
      if (pp->parent == p)
    8000287a:	7c9c                	ld	a5,56(s1)
    8000287c:	ff279be3          	bne	a5,s2,80002872 <wait+0xba>
        acquire(&pp->lock);
    80002880:	8526                	mv	a0,s1
    80002882:	ffffe097          	auipc	ra,0xffffe
    80002886:	368080e7          	jalr	872(ra) # 80000bea <acquire>
        if (pp->state == ZOMBIE)
    8000288a:	4c9c                	lw	a5,24(s1)
    8000288c:	f94781e3          	beq	a5,s4,8000280e <wait+0x56>
        release(&pp->lock);
    80002890:	8526                	mv	a0,s1
    80002892:	ffffe097          	auipc	ra,0xffffe
    80002896:	40c080e7          	jalr	1036(ra) # 80000c9e <release>
        havekids = 1;
    8000289a:	8756                	mv	a4,s5
    8000289c:	bfd9                	j	80002872 <wait+0xba>
    if (!havekids || killed(p))
    8000289e:	c719                	beqz	a4,800028ac <wait+0xf4>
    800028a0:	854a                	mv	a0,s2
    800028a2:	00000097          	auipc	ra,0x0
    800028a6:	ee4080e7          	jalr	-284(ra) # 80002786 <killed>
    800028aa:	c51d                	beqz	a0,800028d8 <wait+0x120>
      release(&wait_lock);
    800028ac:	0000e517          	auipc	a0,0xe
    800028b0:	56c50513          	addi	a0,a0,1388 # 80010e18 <wait_lock>
    800028b4:	ffffe097          	auipc	ra,0xffffe
    800028b8:	3ea080e7          	jalr	1002(ra) # 80000c9e <release>
      return -1;
    800028bc:	59fd                	li	s3,-1
}
    800028be:	854e                	mv	a0,s3
    800028c0:	60a6                	ld	ra,72(sp)
    800028c2:	6406                	ld	s0,64(sp)
    800028c4:	74e2                	ld	s1,56(sp)
    800028c6:	7942                	ld	s2,48(sp)
    800028c8:	79a2                	ld	s3,40(sp)
    800028ca:	7a02                	ld	s4,32(sp)
    800028cc:	6ae2                	ld	s5,24(sp)
    800028ce:	6b42                	ld	s6,16(sp)
    800028d0:	6ba2                	ld	s7,8(sp)
    800028d2:	6c02                	ld	s8,0(sp)
    800028d4:	6161                	addi	sp,sp,80
    800028d6:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800028d8:	85e2                	mv	a1,s8
    800028da:	854a                	mv	a0,s2
    800028dc:	00000097          	auipc	ra,0x0
    800028e0:	aaa080e7          	jalr	-1366(ra) # 80002386 <sleep>
    havekids = 0;
    800028e4:	bf39                	j	80002802 <wait+0x4a>

00000000800028e6 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800028e6:	7179                	addi	sp,sp,-48
    800028e8:	f406                	sd	ra,40(sp)
    800028ea:	f022                	sd	s0,32(sp)
    800028ec:	ec26                	sd	s1,24(sp)
    800028ee:	e84a                	sd	s2,16(sp)
    800028f0:	e44e                	sd	s3,8(sp)
    800028f2:	e052                	sd	s4,0(sp)
    800028f4:	1800                	addi	s0,sp,48
    800028f6:	84aa                	mv	s1,a0
    800028f8:	892e                	mv	s2,a1
    800028fa:	89b2                	mv	s3,a2
    800028fc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800028fe:	fffff097          	auipc	ra,0xfffff
    80002902:	0c8080e7          	jalr	200(ra) # 800019c6 <myproc>
  if (user_dst)
    80002906:	c08d                	beqz	s1,80002928 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002908:	86d2                	mv	a3,s4
    8000290a:	864e                	mv	a2,s3
    8000290c:	85ca                	mv	a1,s2
    8000290e:	6928                	ld	a0,80(a0)
    80002910:	fffff097          	auipc	ra,0xfffff
    80002914:	d74080e7          	jalr	-652(ra) # 80001684 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002918:	70a2                	ld	ra,40(sp)
    8000291a:	7402                	ld	s0,32(sp)
    8000291c:	64e2                	ld	s1,24(sp)
    8000291e:	6942                	ld	s2,16(sp)
    80002920:	69a2                	ld	s3,8(sp)
    80002922:	6a02                	ld	s4,0(sp)
    80002924:	6145                	addi	sp,sp,48
    80002926:	8082                	ret
    memmove((char *)dst, src, len);
    80002928:	000a061b          	sext.w	a2,s4
    8000292c:	85ce                	mv	a1,s3
    8000292e:	854a                	mv	a0,s2
    80002930:	ffffe097          	auipc	ra,0xffffe
    80002934:	416080e7          	jalr	1046(ra) # 80000d46 <memmove>
    return 0;
    80002938:	8526                	mv	a0,s1
    8000293a:	bff9                	j	80002918 <either_copyout+0x32>

000000008000293c <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000293c:	7179                	addi	sp,sp,-48
    8000293e:	f406                	sd	ra,40(sp)
    80002940:	f022                	sd	s0,32(sp)
    80002942:	ec26                	sd	s1,24(sp)
    80002944:	e84a                	sd	s2,16(sp)
    80002946:	e44e                	sd	s3,8(sp)
    80002948:	e052                	sd	s4,0(sp)
    8000294a:	1800                	addi	s0,sp,48
    8000294c:	892a                	mv	s2,a0
    8000294e:	84ae                	mv	s1,a1
    80002950:	89b2                	mv	s3,a2
    80002952:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002954:	fffff097          	auipc	ra,0xfffff
    80002958:	072080e7          	jalr	114(ra) # 800019c6 <myproc>
  if (user_src)
    8000295c:	c08d                	beqz	s1,8000297e <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    8000295e:	86d2                	mv	a3,s4
    80002960:	864e                	mv	a2,s3
    80002962:	85ca                	mv	a1,s2
    80002964:	6928                	ld	a0,80(a0)
    80002966:	fffff097          	auipc	ra,0xfffff
    8000296a:	daa080e7          	jalr	-598(ra) # 80001710 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    8000296e:	70a2                	ld	ra,40(sp)
    80002970:	7402                	ld	s0,32(sp)
    80002972:	64e2                	ld	s1,24(sp)
    80002974:	6942                	ld	s2,16(sp)
    80002976:	69a2                	ld	s3,8(sp)
    80002978:	6a02                	ld	s4,0(sp)
    8000297a:	6145                	addi	sp,sp,48
    8000297c:	8082                	ret
    memmove(dst, (char *)src, len);
    8000297e:	000a061b          	sext.w	a2,s4
    80002982:	85ce                	mv	a1,s3
    80002984:	854a                	mv	a0,s2
    80002986:	ffffe097          	auipc	ra,0xffffe
    8000298a:	3c0080e7          	jalr	960(ra) # 80000d46 <memmove>
    return 0;
    8000298e:	8526                	mv	a0,s1
    80002990:	bff9                	j	8000296e <either_copyin+0x32>

0000000080002992 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002992:	715d                	addi	sp,sp,-80
    80002994:	e486                	sd	ra,72(sp)
    80002996:	e0a2                	sd	s0,64(sp)
    80002998:	fc26                	sd	s1,56(sp)
    8000299a:	f84a                	sd	s2,48(sp)
    8000299c:	f44e                	sd	s3,40(sp)
    8000299e:	f052                	sd	s4,32(sp)
    800029a0:	ec56                	sd	s5,24(sp)
    800029a2:	e85a                	sd	s6,16(sp)
    800029a4:	e45e                	sd	s7,8(sp)
    800029a6:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    800029a8:	00005517          	auipc	a0,0x5
    800029ac:	72050513          	addi	a0,a0,1824 # 800080c8 <digits+0x88>
    800029b0:	ffffe097          	auipc	ra,0xffffe
    800029b4:	bde080e7          	jalr	-1058(ra) # 8000058e <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800029b8:	0000f497          	auipc	s1,0xf
    800029bc:	9d048493          	addi	s1,s1,-1584 # 80011388 <proc+0x158>
    800029c0:	00015917          	auipc	s2,0x15
    800029c4:	3c890913          	addi	s2,s2,968 # 80017d88 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029c8:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800029ca:	00006997          	auipc	s3,0x6
    800029ce:	8b698993          	addi	s3,s3,-1866 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800029d2:	00006a97          	auipc	s5,0x6
    800029d6:	8b6a8a93          	addi	s5,s5,-1866 # 80008288 <digits+0x248>
    printf("\n");
    800029da:	00005a17          	auipc	s4,0x5
    800029de:	6eea0a13          	addi	s4,s4,1774 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029e2:	00006b97          	auipc	s7,0x6
    800029e6:	8e6b8b93          	addi	s7,s7,-1818 # 800082c8 <states.1800>
    800029ea:	a00d                	j	80002a0c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800029ec:	ed86a583          	lw	a1,-296(a3)
    800029f0:	8556                	mv	a0,s5
    800029f2:	ffffe097          	auipc	ra,0xffffe
    800029f6:	b9c080e7          	jalr	-1124(ra) # 8000058e <printf>
    printf("\n");
    800029fa:	8552                	mv	a0,s4
    800029fc:	ffffe097          	auipc	ra,0xffffe
    80002a00:	b92080e7          	jalr	-1134(ra) # 8000058e <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002a04:	1a848493          	addi	s1,s1,424
    80002a08:	03248163          	beq	s1,s2,80002a2a <procdump+0x98>
    if (p->state == UNUSED)
    80002a0c:	86a6                	mv	a3,s1
    80002a0e:	ec04a783          	lw	a5,-320(s1)
    80002a12:	dbed                	beqz	a5,80002a04 <procdump+0x72>
      state = "???";
    80002a14:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a16:	fcfb6be3          	bltu	s6,a5,800029ec <procdump+0x5a>
    80002a1a:	1782                	slli	a5,a5,0x20
    80002a1c:	9381                	srli	a5,a5,0x20
    80002a1e:	078e                	slli	a5,a5,0x3
    80002a20:	97de                	add	a5,a5,s7
    80002a22:	6390                	ld	a2,0(a5)
    80002a24:	f661                	bnez	a2,800029ec <procdump+0x5a>
      state = "???";
    80002a26:	864e                	mv	a2,s3
    80002a28:	b7d1                	j	800029ec <procdump+0x5a>
  }
    80002a2a:	60a6                	ld	ra,72(sp)
    80002a2c:	6406                	ld	s0,64(sp)
    80002a2e:	74e2                	ld	s1,56(sp)
    80002a30:	7942                	ld	s2,48(sp)
    80002a32:	79a2                	ld	s3,40(sp)
    80002a34:	7a02                	ld	s4,32(sp)
    80002a36:	6ae2                	ld	s5,24(sp)
    80002a38:	6b42                	ld	s6,16(sp)
    80002a3a:	6ba2                	ld	s7,8(sp)
    80002a3c:	6161                	addi	sp,sp,80
    80002a3e:	8082                	ret

0000000080002a40 <swtch>:
    80002a40:	00153023          	sd	ra,0(a0)
    80002a44:	00253423          	sd	sp,8(a0)
    80002a48:	e900                	sd	s0,16(a0)
    80002a4a:	ed04                	sd	s1,24(a0)
    80002a4c:	03253023          	sd	s2,32(a0)
    80002a50:	03353423          	sd	s3,40(a0)
    80002a54:	03453823          	sd	s4,48(a0)
    80002a58:	03553c23          	sd	s5,56(a0)
    80002a5c:	05653023          	sd	s6,64(a0)
    80002a60:	05753423          	sd	s7,72(a0)
    80002a64:	05853823          	sd	s8,80(a0)
    80002a68:	05953c23          	sd	s9,88(a0)
    80002a6c:	07a53023          	sd	s10,96(a0)
    80002a70:	07b53423          	sd	s11,104(a0)
    80002a74:	0005b083          	ld	ra,0(a1)
    80002a78:	0085b103          	ld	sp,8(a1)
    80002a7c:	6980                	ld	s0,16(a1)
    80002a7e:	6d84                	ld	s1,24(a1)
    80002a80:	0205b903          	ld	s2,32(a1)
    80002a84:	0285b983          	ld	s3,40(a1)
    80002a88:	0305ba03          	ld	s4,48(a1)
    80002a8c:	0385ba83          	ld	s5,56(a1)
    80002a90:	0405bb03          	ld	s6,64(a1)
    80002a94:	0485bb83          	ld	s7,72(a1)
    80002a98:	0505bc03          	ld	s8,80(a1)
    80002a9c:	0585bc83          	ld	s9,88(a1)
    80002aa0:	0605bd03          	ld	s10,96(a1)
    80002aa4:	0685bd83          	ld	s11,104(a1)
    80002aa8:	8082                	ret

0000000080002aaa <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002aaa:	1141                	addi	sp,sp,-16
    80002aac:	e406                	sd	ra,8(sp)
    80002aae:	e022                	sd	s0,0(sp)
    80002ab0:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002ab2:	00006597          	auipc	a1,0x6
    80002ab6:	84658593          	addi	a1,a1,-1978 # 800082f8 <states.1800+0x30>
    80002aba:	00015517          	auipc	a0,0x15
    80002abe:	17650513          	addi	a0,a0,374 # 80017c30 <tickslock>
    80002ac2:	ffffe097          	auipc	ra,0xffffe
    80002ac6:	098080e7          	jalr	152(ra) # 80000b5a <initlock>
}
    80002aca:	60a2                	ld	ra,8(sp)
    80002acc:	6402                	ld	s0,0(sp)
    80002ace:	0141                	addi	sp,sp,16
    80002ad0:	8082                	ret

0000000080002ad2 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002ad2:	1141                	addi	sp,sp,-16
    80002ad4:	e422                	sd	s0,8(sp)
    80002ad6:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0"
    80002ad8:	00003797          	auipc	a5,0x3
    80002adc:	7c878793          	addi	a5,a5,1992 # 800062a0 <kernelvec>
    80002ae0:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002ae4:	6422                	ld	s0,8(sp)
    80002ae6:	0141                	addi	sp,sp,16
    80002ae8:	8082                	ret

0000000080002aea <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002aea:	1141                	addi	sp,sp,-16
    80002aec:	e406                	sd	ra,8(sp)
    80002aee:	e022                	sd	s0,0(sp)
    80002af0:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002af2:	fffff097          	auipc	ra,0xfffff
    80002af6:	ed4080e7          	jalr	-300(ra) # 800019c6 <myproc>
  asm volatile("csrr %0, sstatus"
    80002afa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002afe:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0"
    80002b00:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002b04:	00004617          	auipc	a2,0x4
    80002b08:	4fc60613          	addi	a2,a2,1276 # 80007000 <_trampoline>
    80002b0c:	00004697          	auipc	a3,0x4
    80002b10:	4f468693          	addi	a3,a3,1268 # 80007000 <_trampoline>
    80002b14:	8e91                	sub	a3,a3,a2
    80002b16:	040007b7          	lui	a5,0x4000
    80002b1a:	17fd                	addi	a5,a5,-1
    80002b1c:	07b2                	slli	a5,a5,0xc
    80002b1e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0"
    80002b20:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002b24:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp"
    80002b26:	180026f3          	csrr	a3,satp
    80002b2a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002b2c:	6d38                	ld	a4,88(a0)
    80002b2e:	6134                	ld	a3,64(a0)
    80002b30:	6585                	lui	a1,0x1
    80002b32:	96ae                	add	a3,a3,a1
    80002b34:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002b36:	6d38                	ld	a4,88(a0)
    80002b38:	00000697          	auipc	a3,0x0
    80002b3c:	13e68693          	addi	a3,a3,318 # 80002c76 <usertrap>
    80002b40:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002b42:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp"
    80002b44:	8692                	mv	a3,tp
    80002b46:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus"
    80002b48:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002b4c:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002b50:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0"
    80002b54:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002b58:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0"
    80002b5a:	6f18                	ld	a4,24(a4)
    80002b5c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002b60:	6928                	ld	a0,80(a0)
    80002b62:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002b64:	00004717          	auipc	a4,0x4
    80002b68:	53870713          	addi	a4,a4,1336 # 8000709c <userret>
    80002b6c:	8f11                	sub	a4,a4,a2
    80002b6e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002b70:	577d                	li	a4,-1
    80002b72:	177e                	slli	a4,a4,0x3f
    80002b74:	8d59                	or	a0,a0,a4
    80002b76:	9782                	jalr	a5
}
    80002b78:	60a2                	ld	ra,8(sp)
    80002b7a:	6402                	ld	s0,0(sp)
    80002b7c:	0141                	addi	sp,sp,16
    80002b7e:	8082                	ret

0000000080002b80 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002b80:	1101                	addi	sp,sp,-32
    80002b82:	ec06                	sd	ra,24(sp)
    80002b84:	e822                	sd	s0,16(sp)
    80002b86:	e426                	sd	s1,8(sp)
    80002b88:	e04a                	sd	s2,0(sp)
    80002b8a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002b8c:	00015917          	auipc	s2,0x15
    80002b90:	0a490913          	addi	s2,s2,164 # 80017c30 <tickslock>
    80002b94:	854a                	mv	a0,s2
    80002b96:	ffffe097          	auipc	ra,0xffffe
    80002b9a:	054080e7          	jalr	84(ra) # 80000bea <acquire>
  ticks++;
    80002b9e:	00006497          	auipc	s1,0x6
    80002ba2:	ff248493          	addi	s1,s1,-14 # 80008b90 <ticks>
    80002ba6:	409c                	lw	a5,0(s1)
    80002ba8:	2785                	addiw	a5,a5,1
    80002baa:	c09c                	sw	a5,0(s1)
  update_time();
    80002bac:	fffff097          	auipc	ra,0xfffff
    80002bb0:	388080e7          	jalr	904(ra) # 80001f34 <update_time>
  wakeup(&ticks);
    80002bb4:	8526                	mv	a0,s1
    80002bb6:	00000097          	auipc	ra,0x0
    80002bba:	980080e7          	jalr	-1664(ra) # 80002536 <wakeup>
  release(&tickslock);
    80002bbe:	854a                	mv	a0,s2
    80002bc0:	ffffe097          	auipc	ra,0xffffe
    80002bc4:	0de080e7          	jalr	222(ra) # 80000c9e <release>
}
    80002bc8:	60e2                	ld	ra,24(sp)
    80002bca:	6442                	ld	s0,16(sp)
    80002bcc:	64a2                	ld	s1,8(sp)
    80002bce:	6902                	ld	s2,0(sp)
    80002bd0:	6105                	addi	sp,sp,32
    80002bd2:	8082                	ret

0000000080002bd4 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002bd4:	1101                	addi	sp,sp,-32
    80002bd6:	ec06                	sd	ra,24(sp)
    80002bd8:	e822                	sd	s0,16(sp)
    80002bda:	e426                	sd	s1,8(sp)
    80002bdc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause"
    80002bde:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002be2:	00074d63          	bltz	a4,80002bfc <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002be6:	57fd                	li	a5,-1
    80002be8:	17fe                	slli	a5,a5,0x3f
    80002bea:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002bec:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002bee:	06f70363          	beq	a4,a5,80002c54 <devintr+0x80>
  }
}
    80002bf2:	60e2                	ld	ra,24(sp)
    80002bf4:	6442                	ld	s0,16(sp)
    80002bf6:	64a2                	ld	s1,8(sp)
    80002bf8:	6105                	addi	sp,sp,32
    80002bfa:	8082                	ret
      (scause & 0xff) == 9)
    80002bfc:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002c00:	46a5                	li	a3,9
    80002c02:	fed792e3          	bne	a5,a3,80002be6 <devintr+0x12>
    int irq = plic_claim();
    80002c06:	00003097          	auipc	ra,0x3
    80002c0a:	7a2080e7          	jalr	1954(ra) # 800063a8 <plic_claim>
    80002c0e:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002c10:	47a9                	li	a5,10
    80002c12:	02f50763          	beq	a0,a5,80002c40 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002c16:	4785                	li	a5,1
    80002c18:	02f50963          	beq	a0,a5,80002c4a <devintr+0x76>
    return 1;
    80002c1c:	4505                	li	a0,1
    else if (irq)
    80002c1e:	d8f1                	beqz	s1,80002bf2 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002c20:	85a6                	mv	a1,s1
    80002c22:	00005517          	auipc	a0,0x5
    80002c26:	6de50513          	addi	a0,a0,1758 # 80008300 <states.1800+0x38>
    80002c2a:	ffffe097          	auipc	ra,0xffffe
    80002c2e:	964080e7          	jalr	-1692(ra) # 8000058e <printf>
      plic_complete(irq);
    80002c32:	8526                	mv	a0,s1
    80002c34:	00003097          	auipc	ra,0x3
    80002c38:	798080e7          	jalr	1944(ra) # 800063cc <plic_complete>
    return 1;
    80002c3c:	4505                	li	a0,1
    80002c3e:	bf55                	j	80002bf2 <devintr+0x1e>
      uartintr();
    80002c40:	ffffe097          	auipc	ra,0xffffe
    80002c44:	d6e080e7          	jalr	-658(ra) # 800009ae <uartintr>
    80002c48:	b7ed                	j	80002c32 <devintr+0x5e>
      virtio_disk_intr();
    80002c4a:	00004097          	auipc	ra,0x4
    80002c4e:	cac080e7          	jalr	-852(ra) # 800068f6 <virtio_disk_intr>
    80002c52:	b7c5                	j	80002c32 <devintr+0x5e>
    if (cpuid() == 0)
    80002c54:	fffff097          	auipc	ra,0xfffff
    80002c58:	d46080e7          	jalr	-698(ra) # 8000199a <cpuid>
    80002c5c:	c901                	beqz	a0,80002c6c <devintr+0x98>
  asm volatile("csrr %0, sip"
    80002c5e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002c62:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0"
    80002c64:	14479073          	csrw	sip,a5
    return 2;
    80002c68:	4509                	li	a0,2
    80002c6a:	b761                	j	80002bf2 <devintr+0x1e>
      clockintr();
    80002c6c:	00000097          	auipc	ra,0x0
    80002c70:	f14080e7          	jalr	-236(ra) # 80002b80 <clockintr>
    80002c74:	b7ed                	j	80002c5e <devintr+0x8a>

0000000080002c76 <usertrap>:
{
    80002c76:	1101                	addi	sp,sp,-32
    80002c78:	ec06                	sd	ra,24(sp)
    80002c7a:	e822                	sd	s0,16(sp)
    80002c7c:	e426                	sd	s1,8(sp)
    80002c7e:	e04a                	sd	s2,0(sp)
    80002c80:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus"
    80002c82:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002c86:	1007f793          	andi	a5,a5,256
    80002c8a:	e3b1                	bnez	a5,80002cce <usertrap+0x58>
  asm volatile("csrw stvec, %0"
    80002c8c:	00003797          	auipc	a5,0x3
    80002c90:	61478793          	addi	a5,a5,1556 # 800062a0 <kernelvec>
    80002c94:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002c98:	fffff097          	auipc	ra,0xfffff
    80002c9c:	d2e080e7          	jalr	-722(ra) # 800019c6 <myproc>
    80002ca0:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002ca2:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc"
    80002ca4:	14102773          	csrr	a4,sepc
    80002ca8:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause"
    80002caa:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002cae:	47a1                	li	a5,8
    80002cb0:	02f70763          	beq	a4,a5,80002cde <usertrap+0x68>
  else if ((which_dev = devintr()) != 0)
    80002cb4:	00000097          	auipc	ra,0x0
    80002cb8:	f20080e7          	jalr	-224(ra) # 80002bd4 <devintr>
    80002cbc:	892a                	mv	s2,a0
    80002cbe:	c92d                	beqz	a0,80002d30 <usertrap+0xba>
  if (killed(p))
    80002cc0:	8526                	mv	a0,s1
    80002cc2:	00000097          	auipc	ra,0x0
    80002cc6:	ac4080e7          	jalr	-1340(ra) # 80002786 <killed>
    80002cca:	c555                	beqz	a0,80002d76 <usertrap+0x100>
    80002ccc:	a045                	j	80002d6c <usertrap+0xf6>
    panic("usertrap: not from user mode");
    80002cce:	00005517          	auipc	a0,0x5
    80002cd2:	65250513          	addi	a0,a0,1618 # 80008320 <states.1800+0x58>
    80002cd6:	ffffe097          	auipc	ra,0xffffe
    80002cda:	86e080e7          	jalr	-1938(ra) # 80000544 <panic>
    if (killed(p))
    80002cde:	00000097          	auipc	ra,0x0
    80002ce2:	aa8080e7          	jalr	-1368(ra) # 80002786 <killed>
    80002ce6:	ed1d                	bnez	a0,80002d24 <usertrap+0xae>
    p->trapframe->epc += 4;
    80002ce8:	6cb8                	ld	a4,88(s1)
    80002cea:	6f1c                	ld	a5,24(a4)
    80002cec:	0791                	addi	a5,a5,4
    80002cee:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus"
    80002cf0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002cf4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0"
    80002cf8:	10079073          	csrw	sstatus,a5
    syscall();
    80002cfc:	00000097          	auipc	ra,0x0
    80002d00:	30e080e7          	jalr	782(ra) # 8000300a <syscall>
  if (killed(p))
    80002d04:	8526                	mv	a0,s1
    80002d06:	00000097          	auipc	ra,0x0
    80002d0a:	a80080e7          	jalr	-1408(ra) # 80002786 <killed>
    80002d0e:	ed31                	bnez	a0,80002d6a <usertrap+0xf4>
  usertrapret();
    80002d10:	00000097          	auipc	ra,0x0
    80002d14:	dda080e7          	jalr	-550(ra) # 80002aea <usertrapret>
}
    80002d18:	60e2                	ld	ra,24(sp)
    80002d1a:	6442                	ld	s0,16(sp)
    80002d1c:	64a2                	ld	s1,8(sp)
    80002d1e:	6902                	ld	s2,0(sp)
    80002d20:	6105                	addi	sp,sp,32
    80002d22:	8082                	ret
      exit(-1);
    80002d24:	557d                	li	a0,-1
    80002d26:	00000097          	auipc	ra,0x0
    80002d2a:	8e0080e7          	jalr	-1824(ra) # 80002606 <exit>
    80002d2e:	bf6d                	j	80002ce8 <usertrap+0x72>
  asm volatile("csrr %0, scause"
    80002d30:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002d34:	5890                	lw	a2,48(s1)
    80002d36:	00005517          	auipc	a0,0x5
    80002d3a:	60a50513          	addi	a0,a0,1546 # 80008340 <states.1800+0x78>
    80002d3e:	ffffe097          	auipc	ra,0xffffe
    80002d42:	850080e7          	jalr	-1968(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc"
    80002d46:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval"
    80002d4a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d4e:	00005517          	auipc	a0,0x5
    80002d52:	62250513          	addi	a0,a0,1570 # 80008370 <states.1800+0xa8>
    80002d56:	ffffe097          	auipc	ra,0xffffe
    80002d5a:	838080e7          	jalr	-1992(ra) # 8000058e <printf>
    setkilled(p);
    80002d5e:	8526                	mv	a0,s1
    80002d60:	00000097          	auipc	ra,0x0
    80002d64:	9fa080e7          	jalr	-1542(ra) # 8000275a <setkilled>
    80002d68:	bf71                	j	80002d04 <usertrap+0x8e>
  if (killed(p))
    80002d6a:	4901                	li	s2,0
    exit(-1);
    80002d6c:	557d                	li	a0,-1
    80002d6e:	00000097          	auipc	ra,0x0
    80002d72:	898080e7          	jalr	-1896(ra) # 80002606 <exit>
  if (which_dev == 2)
    80002d76:	4789                	li	a5,2
    80002d78:	f8f91ce3          	bne	s2,a5,80002d10 <usertrap+0x9a>
    p->CPU_ticks++;
    80002d7c:	1784a783          	lw	a5,376(s1)
    80002d80:	2785                	addiw	a5,a5,1
    80002d82:	16f4ac23          	sw	a5,376(s1)
    if (p->sigalarm != 0)
    80002d86:	16c4a703          	lw	a4,364(s1)
    80002d8a:	d359                	beqz	a4,80002d10 <usertrap+0x9a>
      if ((p->CPU_ticks) % (p->sigalarm_interval) == 0)
    80002d8c:	1704a703          	lw	a4,368(s1)
    80002d90:	02e7e7bb          	remw	a5,a5,a4
    80002d94:	ffb5                	bnez	a5,80002d10 <usertrap+0x9a>
        p->sigalarm = 0;
    80002d96:	1604a623          	sw	zero,364(s1)
        *(p->cpy_trapframe) = *(p->trapframe);
    80002d9a:	6cb4                	ld	a3,88(s1)
    80002d9c:	87b6                	mv	a5,a3
    80002d9e:	1804b703          	ld	a4,384(s1)
    80002da2:	12068693          	addi	a3,a3,288
    80002da6:	0007b803          	ld	a6,0(a5)
    80002daa:	6788                	ld	a0,8(a5)
    80002dac:	6b8c                	ld	a1,16(a5)
    80002dae:	6f90                	ld	a2,24(a5)
    80002db0:	01073023          	sd	a6,0(a4)
    80002db4:	e708                	sd	a0,8(a4)
    80002db6:	eb0c                	sd	a1,16(a4)
    80002db8:	ef10                	sd	a2,24(a4)
    80002dba:	02078793          	addi	a5,a5,32
    80002dbe:	02070713          	addi	a4,a4,32
    80002dc2:	fed792e3          	bne	a5,a3,80002da6 <usertrap+0x130>
        p->trapframe->epc = p->sigalarm_handler;
    80002dc6:	6cbc                	ld	a5,88(s1)
    80002dc8:	1744a703          	lw	a4,372(s1)
    80002dcc:	ef98                	sd	a4,24(a5)
    80002dce:	b789                	j	80002d10 <usertrap+0x9a>

0000000080002dd0 <kerneltrap>:
{
    80002dd0:	7179                	addi	sp,sp,-48
    80002dd2:	f406                	sd	ra,40(sp)
    80002dd4:	f022                	sd	s0,32(sp)
    80002dd6:	ec26                	sd	s1,24(sp)
    80002dd8:	e84a                	sd	s2,16(sp)
    80002dda:	e44e                	sd	s3,8(sp)
    80002ddc:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc"
    80002dde:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus"
    80002de2:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause"
    80002de6:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002dea:	1004f793          	andi	a5,s1,256
    80002dee:	cb85                	beqz	a5,80002e1e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus"
    80002df0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002df4:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002df6:	ef85                	bnez	a5,80002e2e <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002df8:	00000097          	auipc	ra,0x0
    80002dfc:	ddc080e7          	jalr	-548(ra) # 80002bd4 <devintr>
    80002e00:	cd1d                	beqz	a0,80002e3e <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e02:	4789                	li	a5,2
    80002e04:	06f50a63          	beq	a0,a5,80002e78 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0"
    80002e08:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0"
    80002e0c:	10049073          	csrw	sstatus,s1
}
    80002e10:	70a2                	ld	ra,40(sp)
    80002e12:	7402                	ld	s0,32(sp)
    80002e14:	64e2                	ld	s1,24(sp)
    80002e16:	6942                	ld	s2,16(sp)
    80002e18:	69a2                	ld	s3,8(sp)
    80002e1a:	6145                	addi	sp,sp,48
    80002e1c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002e1e:	00005517          	auipc	a0,0x5
    80002e22:	57250513          	addi	a0,a0,1394 # 80008390 <states.1800+0xc8>
    80002e26:	ffffd097          	auipc	ra,0xffffd
    80002e2a:	71e080e7          	jalr	1822(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    80002e2e:	00005517          	auipc	a0,0x5
    80002e32:	58a50513          	addi	a0,a0,1418 # 800083b8 <states.1800+0xf0>
    80002e36:	ffffd097          	auipc	ra,0xffffd
    80002e3a:	70e080e7          	jalr	1806(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    80002e3e:	85ce                	mv	a1,s3
    80002e40:	00005517          	auipc	a0,0x5
    80002e44:	59850513          	addi	a0,a0,1432 # 800083d8 <states.1800+0x110>
    80002e48:	ffffd097          	auipc	ra,0xffffd
    80002e4c:	746080e7          	jalr	1862(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc"
    80002e50:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval"
    80002e54:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e58:	00005517          	auipc	a0,0x5
    80002e5c:	59050513          	addi	a0,a0,1424 # 800083e8 <states.1800+0x120>
    80002e60:	ffffd097          	auipc	ra,0xffffd
    80002e64:	72e080e7          	jalr	1838(ra) # 8000058e <printf>
    panic("kerneltrap");
    80002e68:	00005517          	auipc	a0,0x5
    80002e6c:	59850513          	addi	a0,a0,1432 # 80008400 <states.1800+0x138>
    80002e70:	ffffd097          	auipc	ra,0xffffd
    80002e74:	6d4080e7          	jalr	1748(ra) # 80000544 <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e78:	fffff097          	auipc	ra,0xfffff
    80002e7c:	b4e080e7          	jalr	-1202(ra) # 800019c6 <myproc>
    80002e80:	d541                	beqz	a0,80002e08 <kerneltrap+0x38>
    80002e82:	fffff097          	auipc	ra,0xfffff
    80002e86:	b44080e7          	jalr	-1212(ra) # 800019c6 <myproc>
    80002e8a:	bfbd                	j	80002e08 <kerneltrap+0x38>

0000000080002e8c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002e8c:	1101                	addi	sp,sp,-32
    80002e8e:	ec06                	sd	ra,24(sp)
    80002e90:	e822                	sd	s0,16(sp)
    80002e92:	e426                	sd	s1,8(sp)
    80002e94:	1000                	addi	s0,sp,32
    80002e96:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002e98:	fffff097          	auipc	ra,0xfffff
    80002e9c:	b2e080e7          	jalr	-1234(ra) # 800019c6 <myproc>
  switch (n)
    80002ea0:	4795                	li	a5,5
    80002ea2:	0497e163          	bltu	a5,s1,80002ee4 <argraw+0x58>
    80002ea6:	048a                	slli	s1,s1,0x2
    80002ea8:	00005717          	auipc	a4,0x5
    80002eac:	6b870713          	addi	a4,a4,1720 # 80008560 <states.1800+0x298>
    80002eb0:	94ba                	add	s1,s1,a4
    80002eb2:	409c                	lw	a5,0(s1)
    80002eb4:	97ba                	add	a5,a5,a4
    80002eb6:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002eb8:	6d3c                	ld	a5,88(a0)
    80002eba:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ebc:	60e2                	ld	ra,24(sp)
    80002ebe:	6442                	ld	s0,16(sp)
    80002ec0:	64a2                	ld	s1,8(sp)
    80002ec2:	6105                	addi	sp,sp,32
    80002ec4:	8082                	ret
    return p->trapframe->a1;
    80002ec6:	6d3c                	ld	a5,88(a0)
    80002ec8:	7fa8                	ld	a0,120(a5)
    80002eca:	bfcd                	j	80002ebc <argraw+0x30>
    return p->trapframe->a2;
    80002ecc:	6d3c                	ld	a5,88(a0)
    80002ece:	63c8                	ld	a0,128(a5)
    80002ed0:	b7f5                	j	80002ebc <argraw+0x30>
    return p->trapframe->a3;
    80002ed2:	6d3c                	ld	a5,88(a0)
    80002ed4:	67c8                	ld	a0,136(a5)
    80002ed6:	b7dd                	j	80002ebc <argraw+0x30>
    return p->trapframe->a4;
    80002ed8:	6d3c                	ld	a5,88(a0)
    80002eda:	6bc8                	ld	a0,144(a5)
    80002edc:	b7c5                	j	80002ebc <argraw+0x30>
    return p->trapframe->a5;
    80002ede:	6d3c                	ld	a5,88(a0)
    80002ee0:	6fc8                	ld	a0,152(a5)
    80002ee2:	bfe9                	j	80002ebc <argraw+0x30>
  panic("argraw");
    80002ee4:	00005517          	auipc	a0,0x5
    80002ee8:	52c50513          	addi	a0,a0,1324 # 80008410 <states.1800+0x148>
    80002eec:	ffffd097          	auipc	ra,0xffffd
    80002ef0:	658080e7          	jalr	1624(ra) # 80000544 <panic>

0000000080002ef4 <fetchaddr>:
{
    80002ef4:	1101                	addi	sp,sp,-32
    80002ef6:	ec06                	sd	ra,24(sp)
    80002ef8:	e822                	sd	s0,16(sp)
    80002efa:	e426                	sd	s1,8(sp)
    80002efc:	e04a                	sd	s2,0(sp)
    80002efe:	1000                	addi	s0,sp,32
    80002f00:	84aa                	mv	s1,a0
    80002f02:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002f04:	fffff097          	auipc	ra,0xfffff
    80002f08:	ac2080e7          	jalr	-1342(ra) # 800019c6 <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002f0c:	653c                	ld	a5,72(a0)
    80002f0e:	02f4f863          	bgeu	s1,a5,80002f3e <fetchaddr+0x4a>
    80002f12:	00848713          	addi	a4,s1,8
    80002f16:	02e7e663          	bltu	a5,a4,80002f42 <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002f1a:	46a1                	li	a3,8
    80002f1c:	8626                	mv	a2,s1
    80002f1e:	85ca                	mv	a1,s2
    80002f20:	6928                	ld	a0,80(a0)
    80002f22:	ffffe097          	auipc	ra,0xffffe
    80002f26:	7ee080e7          	jalr	2030(ra) # 80001710 <copyin>
    80002f2a:	00a03533          	snez	a0,a0
    80002f2e:	40a00533          	neg	a0,a0
}
    80002f32:	60e2                	ld	ra,24(sp)
    80002f34:	6442                	ld	s0,16(sp)
    80002f36:	64a2                	ld	s1,8(sp)
    80002f38:	6902                	ld	s2,0(sp)
    80002f3a:	6105                	addi	sp,sp,32
    80002f3c:	8082                	ret
    return -1;
    80002f3e:	557d                	li	a0,-1
    80002f40:	bfcd                	j	80002f32 <fetchaddr+0x3e>
    80002f42:	557d                	li	a0,-1
    80002f44:	b7fd                	j	80002f32 <fetchaddr+0x3e>

0000000080002f46 <fetchstr>:
{
    80002f46:	7179                	addi	sp,sp,-48
    80002f48:	f406                	sd	ra,40(sp)
    80002f4a:	f022                	sd	s0,32(sp)
    80002f4c:	ec26                	sd	s1,24(sp)
    80002f4e:	e84a                	sd	s2,16(sp)
    80002f50:	e44e                	sd	s3,8(sp)
    80002f52:	1800                	addi	s0,sp,48
    80002f54:	892a                	mv	s2,a0
    80002f56:	84ae                	mv	s1,a1
    80002f58:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002f5a:	fffff097          	auipc	ra,0xfffff
    80002f5e:	a6c080e7          	jalr	-1428(ra) # 800019c6 <myproc>
  if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002f62:	86ce                	mv	a3,s3
    80002f64:	864a                	mv	a2,s2
    80002f66:	85a6                	mv	a1,s1
    80002f68:	6928                	ld	a0,80(a0)
    80002f6a:	fffff097          	auipc	ra,0xfffff
    80002f6e:	832080e7          	jalr	-1998(ra) # 8000179c <copyinstr>
    80002f72:	00054e63          	bltz	a0,80002f8e <fetchstr+0x48>
  return strlen(buf);
    80002f76:	8526                	mv	a0,s1
    80002f78:	ffffe097          	auipc	ra,0xffffe
    80002f7c:	ef2080e7          	jalr	-270(ra) # 80000e6a <strlen>
}
    80002f80:	70a2                	ld	ra,40(sp)
    80002f82:	7402                	ld	s0,32(sp)
    80002f84:	64e2                	ld	s1,24(sp)
    80002f86:	6942                	ld	s2,16(sp)
    80002f88:	69a2                	ld	s3,8(sp)
    80002f8a:	6145                	addi	sp,sp,48
    80002f8c:	8082                	ret
    return -1;
    80002f8e:	557d                	li	a0,-1
    80002f90:	bfc5                	j	80002f80 <fetchstr+0x3a>

0000000080002f92 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80002f92:	1101                	addi	sp,sp,-32
    80002f94:	ec06                	sd	ra,24(sp)
    80002f96:	e822                	sd	s0,16(sp)
    80002f98:	e426                	sd	s1,8(sp)
    80002f9a:	1000                	addi	s0,sp,32
    80002f9c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f9e:	00000097          	auipc	ra,0x0
    80002fa2:	eee080e7          	jalr	-274(ra) # 80002e8c <argraw>
    80002fa6:	c088                	sw	a0,0(s1)
}
    80002fa8:	60e2                	ld	ra,24(sp)
    80002faa:	6442                	ld	s0,16(sp)
    80002fac:	64a2                	ld	s1,8(sp)
    80002fae:	6105                	addi	sp,sp,32
    80002fb0:	8082                	ret

0000000080002fb2 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80002fb2:	1101                	addi	sp,sp,-32
    80002fb4:	ec06                	sd	ra,24(sp)
    80002fb6:	e822                	sd	s0,16(sp)
    80002fb8:	e426                	sd	s1,8(sp)
    80002fba:	1000                	addi	s0,sp,32
    80002fbc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002fbe:	00000097          	auipc	ra,0x0
    80002fc2:	ece080e7          	jalr	-306(ra) # 80002e8c <argraw>
    80002fc6:	e088                	sd	a0,0(s1)
}
    80002fc8:	60e2                	ld	ra,24(sp)
    80002fca:	6442                	ld	s0,16(sp)
    80002fcc:	64a2                	ld	s1,8(sp)
    80002fce:	6105                	addi	sp,sp,32
    80002fd0:	8082                	ret

0000000080002fd2 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002fd2:	7179                	addi	sp,sp,-48
    80002fd4:	f406                	sd	ra,40(sp)
    80002fd6:	f022                	sd	s0,32(sp)
    80002fd8:	ec26                	sd	s1,24(sp)
    80002fda:	e84a                	sd	s2,16(sp)
    80002fdc:	1800                	addi	s0,sp,48
    80002fde:	84ae                	mv	s1,a1
    80002fe0:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002fe2:	fd840593          	addi	a1,s0,-40
    80002fe6:	00000097          	auipc	ra,0x0
    80002fea:	fcc080e7          	jalr	-52(ra) # 80002fb2 <argaddr>
  return fetchstr(addr, buf, max);
    80002fee:	864a                	mv	a2,s2
    80002ff0:	85a6                	mv	a1,s1
    80002ff2:	fd843503          	ld	a0,-40(s0)
    80002ff6:	00000097          	auipc	ra,0x0
    80002ffa:	f50080e7          	jalr	-176(ra) # 80002f46 <fetchstr>
}
    80002ffe:	70a2                	ld	ra,40(sp)
    80003000:	7402                	ld	s0,32(sp)
    80003002:	64e2                	ld	s1,24(sp)
    80003004:	6942                	ld	s2,16(sp)
    80003006:	6145                	addi	sp,sp,48
    80003008:	8082                	ret

000000008000300a <syscall>:
    2,
    3,
};

void syscall(void)
{
    8000300a:	711d                	addi	sp,sp,-96
    8000300c:	ec86                	sd	ra,88(sp)
    8000300e:	e8a2                	sd	s0,80(sp)
    80003010:	e4a6                	sd	s1,72(sp)
    80003012:	e0ca                	sd	s2,64(sp)
    80003014:	fc4e                	sd	s3,56(sp)
    80003016:	f852                	sd	s4,48(sp)
    80003018:	f456                	sd	s5,40(sp)
    8000301a:	f05a                	sd	s6,32(sp)
    8000301c:	ec5e                	sd	s7,24(sp)
    8000301e:	e862                	sd	s8,16(sp)
    80003020:	e466                	sd	s9,8(sp)
    80003022:	1080                	addi	s0,sp,96
  int num;
  struct proc *p = myproc();
    80003024:	fffff097          	auipc	ra,0xfffff
    80003028:	9a2080e7          	jalr	-1630(ra) # 800019c6 <myproc>
    8000302c:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000302e:	05853903          	ld	s2,88(a0)
    80003032:	0a893983          	ld	s3,168(s2)
    80003036:	00098a1b          	sext.w	s4,s3
  int a0 = p->trapframe->a0;
    8000303a:	07093b03          	ld	s6,112(s2)
  int a1 = p->trapframe->a1;
    8000303e:	07893c03          	ld	s8,120(s2)
  int a2 = p->trapframe->a2;
    80003042:	08093b83          	ld	s7,128(s2)
  p->trapframe->a0 = syscalls[num]();
    80003046:	003a1713          	slli	a4,s4,0x3
    8000304a:	00005797          	auipc	a5,0x5
    8000304e:	52e78793          	addi	a5,a5,1326 # 80008578 <syscalls>
    80003052:	97ba                	add	a5,a5,a4
    80003054:	0007ba83          	ld	s5,0(a5)
    80003058:	9a82                	jalr	s5
    8000305a:	06a93823          	sd	a0,112(s2)
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    8000305e:	39fd                	addiw	s3,s3,-1
    80003060:	47e9                	li	a5,26
    80003062:	0d37e063          	bltu	a5,s3,80003122 <syscall+0x118>
    80003066:	0a0a8e63          	beqz	s5,80003122 <syscall+0x118>
  {
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    if (p->strace != -1 && (p->strace & 1 << num))
    8000306a:	1684a783          	lw	a5,360(s1)
    8000306e:	577d                	li	a4,-1
    80003070:	0ce78863          	beq	a5,a4,80003140 <syscall+0x136>
    80003074:	4147d7bb          	sraw	a5,a5,s4
    80003078:	8b85                	andi	a5,a5,1
    8000307a:	c3f9                	beqz	a5,80003140 <syscall+0x136>
    {
      printf("%d: syscall %s ( ", p->pid, syscall_name[num]);
    8000307c:	00006917          	auipc	s2,0x6
    80003080:	96c90913          	addi	s2,s2,-1684 # 800089e8 <syscall_name>
    80003084:	003a1793          	slli	a5,s4,0x3
    80003088:	97ca                	add	a5,a5,s2
    8000308a:	6390                	ld	a2,0(a5)
    8000308c:	588c                	lw	a1,48(s1)
    8000308e:	00005517          	auipc	a0,0x5
    80003092:	38a50513          	addi	a0,a0,906 # 80008418 <states.1800+0x150>
    80003096:	ffffd097          	auipc	ra,0xffffd
    8000309a:	4f8080e7          	jalr	1272(ra) # 8000058e <printf>
      for (int i = 0; i < syscall_argc[num]; i++)
    8000309e:	002a1793          	slli	a5,s4,0x2
    800030a2:	993e                	add	s2,s2,a5
    800030a4:	0e092783          	lw	a5,224(s2)
    800030a8:	06f05263          	blez	a5,8000310c <syscall+0x102>
  int a0 = p->trapframe->a0;
    800030ac:	2b01                	sext.w	s6,s6
  int a1 = p->trapframe->a1;
    800030ae:	2c01                	sext.w	s8,s8
  int a2 = p->trapframe->a2;
    800030b0:	2b81                	sext.w	s7,s7
      for (int i = 0; i < syscall_argc[num]; i++)
    800030b2:	4901                	li	s2,0
      {
        if (i == 0)
        {
          printf("%d ", a0);
        }
        if (i == 1)
    800030b4:	4a85                	li	s5,1
        {
          printf("%d ", a1);
        }
        if (i == 2)
    800030b6:	4c89                	li	s9,2
        {
          printf("%d ", a2);
    800030b8:	00005997          	auipc	s3,0x5
    800030bc:	37898993          	addi	s3,s3,888 # 80008430 <states.1800+0x168>
      for (int i = 0; i < syscall_argc[num]; i++)
    800030c0:	0a0a                	slli	s4,s4,0x2
    800030c2:	00006797          	auipc	a5,0x6
    800030c6:	92678793          	addi	a5,a5,-1754 # 800089e8 <syscall_name>
    800030ca:	9a3e                	add	s4,s4,a5
    800030cc:	a821                	j	800030e4 <syscall+0xda>
          printf("%d ", a0);
    800030ce:	85da                	mv	a1,s6
    800030d0:	854e                	mv	a0,s3
    800030d2:	ffffd097          	auipc	ra,0xffffd
    800030d6:	4bc080e7          	jalr	1212(ra) # 8000058e <printf>
      for (int i = 0; i < syscall_argc[num]; i++)
    800030da:	2905                	addiw	s2,s2,1
    800030dc:	0e0a2783          	lw	a5,224(s4)
    800030e0:	02f95663          	bge	s2,a5,8000310c <syscall+0x102>
        if (i == 0)
    800030e4:	fe0905e3          	beqz	s2,800030ce <syscall+0xc4>
        if (i == 1)
    800030e8:	01590b63          	beq	s2,s5,800030fe <syscall+0xf4>
        if (i == 2)
    800030ec:	ff9917e3          	bne	s2,s9,800030da <syscall+0xd0>
          printf("%d ", a2);
    800030f0:	85de                	mv	a1,s7
    800030f2:	854e                	mv	a0,s3
    800030f4:	ffffd097          	auipc	ra,0xffffd
    800030f8:	49a080e7          	jalr	1178(ra) # 8000058e <printf>
    800030fc:	bff9                	j	800030da <syscall+0xd0>
          printf("%d ", a1);
    800030fe:	85e2                	mv	a1,s8
    80003100:	854e                	mv	a0,s3
    80003102:	ffffd097          	auipc	ra,0xffffd
    80003106:	48c080e7          	jalr	1164(ra) # 8000058e <printf>
        if (i == 2)
    8000310a:	bfc1                	j	800030da <syscall+0xd0>
        }
      }
      printf(") -> %d\n", p->trapframe->a0);
    8000310c:	6cbc                	ld	a5,88(s1)
    8000310e:	7bac                	ld	a1,112(a5)
    80003110:	00005517          	auipc	a0,0x5
    80003114:	32850513          	addi	a0,a0,808 # 80008438 <states.1800+0x170>
    80003118:	ffffd097          	auipc	ra,0xffffd
    8000311c:	476080e7          	jalr	1142(ra) # 8000058e <printf>
    80003120:	a005                	j	80003140 <syscall+0x136>
    }
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80003122:	86d2                	mv	a3,s4
    80003124:	15848613          	addi	a2,s1,344
    80003128:	588c                	lw	a1,48(s1)
    8000312a:	00005517          	auipc	a0,0x5
    8000312e:	31e50513          	addi	a0,a0,798 # 80008448 <states.1800+0x180>
    80003132:	ffffd097          	auipc	ra,0xffffd
    80003136:	45c080e7          	jalr	1116(ra) # 8000058e <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000313a:	6cbc                	ld	a5,88(s1)
    8000313c:	577d                	li	a4,-1
    8000313e:	fbb8                	sd	a4,112(a5)
  }
    80003140:	60e6                	ld	ra,88(sp)
    80003142:	6446                	ld	s0,80(sp)
    80003144:	64a6                	ld	s1,72(sp)
    80003146:	6906                	ld	s2,64(sp)
    80003148:	79e2                	ld	s3,56(sp)
    8000314a:	7a42                	ld	s4,48(sp)
    8000314c:	7aa2                	ld	s5,40(sp)
    8000314e:	7b02                	ld	s6,32(sp)
    80003150:	6be2                	ld	s7,24(sp)
    80003152:	6c42                	ld	s8,16(sp)
    80003154:	6ca2                	ld	s9,8(sp)
    80003156:	6125                	addi	sp,sp,96
    80003158:	8082                	ret

000000008000315a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000315a:	1101                	addi	sp,sp,-32
    8000315c:	ec06                	sd	ra,24(sp)
    8000315e:	e822                	sd	s0,16(sp)
    80003160:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80003162:	fec40593          	addi	a1,s0,-20
    80003166:	4501                	li	a0,0
    80003168:	00000097          	auipc	ra,0x0
    8000316c:	e2a080e7          	jalr	-470(ra) # 80002f92 <argint>
  exit(n);
    80003170:	fec42503          	lw	a0,-20(s0)
    80003174:	fffff097          	auipc	ra,0xfffff
    80003178:	492080e7          	jalr	1170(ra) # 80002606 <exit>
  return 0; // not reached
}
    8000317c:	4501                	li	a0,0
    8000317e:	60e2                	ld	ra,24(sp)
    80003180:	6442                	ld	s0,16(sp)
    80003182:	6105                	addi	sp,sp,32
    80003184:	8082                	ret

0000000080003186 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003186:	1141                	addi	sp,sp,-16
    80003188:	e406                	sd	ra,8(sp)
    8000318a:	e022                	sd	s0,0(sp)
    8000318c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000318e:	fffff097          	auipc	ra,0xfffff
    80003192:	838080e7          	jalr	-1992(ra) # 800019c6 <myproc>
}
    80003196:	5908                	lw	a0,48(a0)
    80003198:	60a2                	ld	ra,8(sp)
    8000319a:	6402                	ld	s0,0(sp)
    8000319c:	0141                	addi	sp,sp,16
    8000319e:	8082                	ret

00000000800031a0 <sys_fork>:

uint64
sys_fork(void)
{
    800031a0:	1141                	addi	sp,sp,-16
    800031a2:	e406                	sd	ra,8(sp)
    800031a4:	e022                	sd	s0,0(sp)
    800031a6:	0800                	addi	s0,sp,16
  return fork();
    800031a8:	fffff097          	auipc	ra,0xfffff
    800031ac:	c50080e7          	jalr	-944(ra) # 80001df8 <fork>
}
    800031b0:	60a2                	ld	ra,8(sp)
    800031b2:	6402                	ld	s0,0(sp)
    800031b4:	0141                	addi	sp,sp,16
    800031b6:	8082                	ret

00000000800031b8 <sys_wait>:

uint64
sys_wait(void)
{
    800031b8:	1101                	addi	sp,sp,-32
    800031ba:	ec06                	sd	ra,24(sp)
    800031bc:	e822                	sd	s0,16(sp)
    800031be:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    800031c0:	fe840593          	addi	a1,s0,-24
    800031c4:	4501                	li	a0,0
    800031c6:	00000097          	auipc	ra,0x0
    800031ca:	dec080e7          	jalr	-532(ra) # 80002fb2 <argaddr>
  return wait(p);
    800031ce:	fe843503          	ld	a0,-24(s0)
    800031d2:	fffff097          	auipc	ra,0xfffff
    800031d6:	5e6080e7          	jalr	1510(ra) # 800027b8 <wait>
}
    800031da:	60e2                	ld	ra,24(sp)
    800031dc:	6442                	ld	s0,16(sp)
    800031de:	6105                	addi	sp,sp,32
    800031e0:	8082                	ret

00000000800031e2 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800031e2:	7179                	addi	sp,sp,-48
    800031e4:	f406                	sd	ra,40(sp)
    800031e6:	f022                	sd	s0,32(sp)
    800031e8:	ec26                	sd	s1,24(sp)
    800031ea:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    800031ec:	fdc40593          	addi	a1,s0,-36
    800031f0:	4501                	li	a0,0
    800031f2:	00000097          	auipc	ra,0x0
    800031f6:	da0080e7          	jalr	-608(ra) # 80002f92 <argint>
  addr = myproc()->sz;
    800031fa:	ffffe097          	auipc	ra,0xffffe
    800031fe:	7cc080e7          	jalr	1996(ra) # 800019c6 <myproc>
    80003202:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80003204:	fdc42503          	lw	a0,-36(s0)
    80003208:	fffff097          	auipc	ra,0xfffff
    8000320c:	b94080e7          	jalr	-1132(ra) # 80001d9c <growproc>
    80003210:	00054863          	bltz	a0,80003220 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80003214:	8526                	mv	a0,s1
    80003216:	70a2                	ld	ra,40(sp)
    80003218:	7402                	ld	s0,32(sp)
    8000321a:	64e2                	ld	s1,24(sp)
    8000321c:	6145                	addi	sp,sp,48
    8000321e:	8082                	ret
    return -1;
    80003220:	54fd                	li	s1,-1
    80003222:	bfcd                	j	80003214 <sys_sbrk+0x32>

0000000080003224 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003224:	7139                	addi	sp,sp,-64
    80003226:	fc06                	sd	ra,56(sp)
    80003228:	f822                	sd	s0,48(sp)
    8000322a:	f426                	sd	s1,40(sp)
    8000322c:	f04a                	sd	s2,32(sp)
    8000322e:	ec4e                	sd	s3,24(sp)
    80003230:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80003232:	fcc40593          	addi	a1,s0,-52
    80003236:	4501                	li	a0,0
    80003238:	00000097          	auipc	ra,0x0
    8000323c:	d5a080e7          	jalr	-678(ra) # 80002f92 <argint>
  acquire(&tickslock);
    80003240:	00015517          	auipc	a0,0x15
    80003244:	9f050513          	addi	a0,a0,-1552 # 80017c30 <tickslock>
    80003248:	ffffe097          	auipc	ra,0xffffe
    8000324c:	9a2080e7          	jalr	-1630(ra) # 80000bea <acquire>
  ticks0 = ticks;
    80003250:	00006917          	auipc	s2,0x6
    80003254:	94092903          	lw	s2,-1728(s2) # 80008b90 <ticks>
  while (ticks - ticks0 < n)
    80003258:	fcc42783          	lw	a5,-52(s0)
    8000325c:	cf9d                	beqz	a5,8000329a <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000325e:	00015997          	auipc	s3,0x15
    80003262:	9d298993          	addi	s3,s3,-1582 # 80017c30 <tickslock>
    80003266:	00006497          	auipc	s1,0x6
    8000326a:	92a48493          	addi	s1,s1,-1750 # 80008b90 <ticks>
    if (killed(myproc()))
    8000326e:	ffffe097          	auipc	ra,0xffffe
    80003272:	758080e7          	jalr	1880(ra) # 800019c6 <myproc>
    80003276:	fffff097          	auipc	ra,0xfffff
    8000327a:	510080e7          	jalr	1296(ra) # 80002786 <killed>
    8000327e:	ed15                	bnez	a0,800032ba <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003280:	85ce                	mv	a1,s3
    80003282:	8526                	mv	a0,s1
    80003284:	fffff097          	auipc	ra,0xfffff
    80003288:	102080e7          	jalr	258(ra) # 80002386 <sleep>
  while (ticks - ticks0 < n)
    8000328c:	409c                	lw	a5,0(s1)
    8000328e:	412787bb          	subw	a5,a5,s2
    80003292:	fcc42703          	lw	a4,-52(s0)
    80003296:	fce7ece3          	bltu	a5,a4,8000326e <sys_sleep+0x4a>
  }
  release(&tickslock);
    8000329a:	00015517          	auipc	a0,0x15
    8000329e:	99650513          	addi	a0,a0,-1642 # 80017c30 <tickslock>
    800032a2:	ffffe097          	auipc	ra,0xffffe
    800032a6:	9fc080e7          	jalr	-1540(ra) # 80000c9e <release>
  return 0;
    800032aa:	4501                	li	a0,0
}
    800032ac:	70e2                	ld	ra,56(sp)
    800032ae:	7442                	ld	s0,48(sp)
    800032b0:	74a2                	ld	s1,40(sp)
    800032b2:	7902                	ld	s2,32(sp)
    800032b4:	69e2                	ld	s3,24(sp)
    800032b6:	6121                	addi	sp,sp,64
    800032b8:	8082                	ret
      release(&tickslock);
    800032ba:	00015517          	auipc	a0,0x15
    800032be:	97650513          	addi	a0,a0,-1674 # 80017c30 <tickslock>
    800032c2:	ffffe097          	auipc	ra,0xffffe
    800032c6:	9dc080e7          	jalr	-1572(ra) # 80000c9e <release>
      return -1;
    800032ca:	557d                	li	a0,-1
    800032cc:	b7c5                	j	800032ac <sys_sleep+0x88>

00000000800032ce <sys_kill>:

uint64
sys_kill(void)
{
    800032ce:	1101                	addi	sp,sp,-32
    800032d0:	ec06                	sd	ra,24(sp)
    800032d2:	e822                	sd	s0,16(sp)
    800032d4:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    800032d6:	fec40593          	addi	a1,s0,-20
    800032da:	4501                	li	a0,0
    800032dc:	00000097          	auipc	ra,0x0
    800032e0:	cb6080e7          	jalr	-842(ra) # 80002f92 <argint>
  return kill(pid);
    800032e4:	fec42503          	lw	a0,-20(s0)
    800032e8:	fffff097          	auipc	ra,0xfffff
    800032ec:	400080e7          	jalr	1024(ra) # 800026e8 <kill>
}
    800032f0:	60e2                	ld	ra,24(sp)
    800032f2:	6442                	ld	s0,16(sp)
    800032f4:	6105                	addi	sp,sp,32
    800032f6:	8082                	ret

00000000800032f8 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800032f8:	1101                	addi	sp,sp,-32
    800032fa:	ec06                	sd	ra,24(sp)
    800032fc:	e822                	sd	s0,16(sp)
    800032fe:	e426                	sd	s1,8(sp)
    80003300:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003302:	00015517          	auipc	a0,0x15
    80003306:	92e50513          	addi	a0,a0,-1746 # 80017c30 <tickslock>
    8000330a:	ffffe097          	auipc	ra,0xffffe
    8000330e:	8e0080e7          	jalr	-1824(ra) # 80000bea <acquire>
  xticks = ticks;
    80003312:	00006497          	auipc	s1,0x6
    80003316:	87e4a483          	lw	s1,-1922(s1) # 80008b90 <ticks>
  release(&tickslock);
    8000331a:	00015517          	auipc	a0,0x15
    8000331e:	91650513          	addi	a0,a0,-1770 # 80017c30 <tickslock>
    80003322:	ffffe097          	auipc	ra,0xffffe
    80003326:	97c080e7          	jalr	-1668(ra) # 80000c9e <release>
  return xticks;
}
    8000332a:	02049513          	slli	a0,s1,0x20
    8000332e:	9101                	srli	a0,a0,0x20
    80003330:	60e2                	ld	ra,24(sp)
    80003332:	6442                	ld	s0,16(sp)
    80003334:	64a2                	ld	s1,8(sp)
    80003336:	6105                	addi	sp,sp,32
    80003338:	8082                	ret

000000008000333a <sys_trace>:

uint64
sys_trace(void)
{
    8000333a:	1101                	addi	sp,sp,-32
    8000333c:	ec06                	sd	ra,24(sp)
    8000333e:	e822                	sd	s0,16(sp)
    80003340:	1000                	addi	s0,sp,32
  int mask;
  argint(0, &mask);
    80003342:	fec40593          	addi	a1,s0,-20
    80003346:	4501                	li	a0,0
    80003348:	00000097          	auipc	ra,0x0
    8000334c:	c4a080e7          	jalr	-950(ra) # 80002f92 <argint>
  myproc()->strace = mask;
    80003350:	ffffe097          	auipc	ra,0xffffe
    80003354:	676080e7          	jalr	1654(ra) # 800019c6 <myproc>
    80003358:	fec42783          	lw	a5,-20(s0)
    8000335c:	16f52423          	sw	a5,360(a0)
  return 0;
}
    80003360:	4501                	li	a0,0
    80003362:	60e2                	ld	ra,24(sp)
    80003364:	6442                	ld	s0,16(sp)
    80003366:	6105                	addi	sp,sp,32
    80003368:	8082                	ret

000000008000336a <sys_sigalarm>:

uint64
sys_sigalarm(void)
{
    8000336a:	7179                	addi	sp,sp,-48
    8000336c:	f406                	sd	ra,40(sp)
    8000336e:	f022                	sd	s0,32(sp)
    80003370:	ec26                	sd	s1,24(sp)
    80003372:	1800                	addi	s0,sp,48
  myproc()->sigalarm = 0;
    80003374:	ffffe097          	auipc	ra,0xffffe
    80003378:	652080e7          	jalr	1618(ra) # 800019c6 <myproc>
    8000337c:	16052623          	sw	zero,364(a0)

  int interval;
  argint(0, &interval);
    80003380:	fdc40593          	addi	a1,s0,-36
    80003384:	4501                	li	a0,0
    80003386:	00000097          	auipc	ra,0x0
    8000338a:	c0c080e7          	jalr	-1012(ra) # 80002f92 <argint>
  myproc()->sigalarm_interval = interval;
    8000338e:	ffffe097          	auipc	ra,0xffffe
    80003392:	638080e7          	jalr	1592(ra) # 800019c6 <myproc>
    80003396:	fdc42783          	lw	a5,-36(s0)
    8000339a:	16f52823          	sw	a5,368(a0)

  uint64 handler;
  argaddr(1, &handler);
    8000339e:	fd040593          	addi	a1,s0,-48
    800033a2:	4505                	li	a0,1
    800033a4:	00000097          	auipc	ra,0x0
    800033a8:	c0e080e7          	jalr	-1010(ra) # 80002fb2 <argaddr>
  myproc()->sigalarm_handler = handler;
    800033ac:	fd043483          	ld	s1,-48(s0)
    800033b0:	ffffe097          	auipc	ra,0xffffe
    800033b4:	616080e7          	jalr	1558(ra) # 800019c6 <myproc>
    800033b8:	16952a23          	sw	s1,372(a0)

  myproc()->CPU_ticks = 0;
    800033bc:	ffffe097          	auipc	ra,0xffffe
    800033c0:	60a080e7          	jalr	1546(ra) # 800019c6 <myproc>
    800033c4:	16052c23          	sw	zero,376(a0)
  myproc()->sigalarm = 1;
    800033c8:	ffffe097          	auipc	ra,0xffffe
    800033cc:	5fe080e7          	jalr	1534(ra) # 800019c6 <myproc>
    800033d0:	4785                	li	a5,1
    800033d2:	16f52623          	sw	a5,364(a0)

  return 0;
}
    800033d6:	4501                	li	a0,0
    800033d8:	70a2                	ld	ra,40(sp)
    800033da:	7402                	ld	s0,32(sp)
    800033dc:	64e2                	ld	s1,24(sp)
    800033de:	6145                	addi	sp,sp,48
    800033e0:	8082                	ret

00000000800033e2 <sys_sigreturn>:

uint64
sys_sigreturn(void)
{
    800033e2:	1101                	addi	sp,sp,-32
    800033e4:	ec06                	sd	ra,24(sp)
    800033e6:	e822                	sd	s0,16(sp)
    800033e8:	e426                	sd	s1,8(sp)
    800033ea:	1000                	addi	s0,sp,32
  *(myproc()->trapframe) = *(myproc()->cpy_trapframe);
    800033ec:	ffffe097          	auipc	ra,0xffffe
    800033f0:	5da080e7          	jalr	1498(ra) # 800019c6 <myproc>
    800033f4:	18053483          	ld	s1,384(a0)
    800033f8:	ffffe097          	auipc	ra,0xffffe
    800033fc:	5ce080e7          	jalr	1486(ra) # 800019c6 <myproc>
    80003400:	87a6                	mv	a5,s1
    80003402:	6d38                	ld	a4,88(a0)
    80003404:	12048493          	addi	s1,s1,288
    80003408:	6388                	ld	a0,0(a5)
    8000340a:	678c                	ld	a1,8(a5)
    8000340c:	6b90                	ld	a2,16(a5)
    8000340e:	6f94                	ld	a3,24(a5)
    80003410:	e308                	sd	a0,0(a4)
    80003412:	e70c                	sd	a1,8(a4)
    80003414:	eb10                	sd	a2,16(a4)
    80003416:	ef14                	sd	a3,24(a4)
    80003418:	02078793          	addi	a5,a5,32
    8000341c:	02070713          	addi	a4,a4,32
    80003420:	fe9794e3          	bne	a5,s1,80003408 <sys_sigreturn+0x26>
  myproc()->sigalarm = 1;
    80003424:	ffffe097          	auipc	ra,0xffffe
    80003428:	5a2080e7          	jalr	1442(ra) # 800019c6 <myproc>
    8000342c:	4785                	li	a5,1
    8000342e:	16f52623          	sw	a5,364(a0)
  usertrapret();
    80003432:	fffff097          	auipc	ra,0xfffff
    80003436:	6b8080e7          	jalr	1720(ra) # 80002aea <usertrapret>

  return 0;
}
    8000343a:	4501                	li	a0,0
    8000343c:	60e2                	ld	ra,24(sp)
    8000343e:	6442                	ld	s0,16(sp)
    80003440:	64a2                	ld	s1,8(sp)
    80003442:	6105                	addi	sp,sp,32
    80003444:	8082                	ret

0000000080003446 <sys_settickets>:

uint64
sys_settickets(void)
{
    80003446:	1141                	addi	sp,sp,-16
    80003448:	e422                	sd	s0,8(sp)
    8000344a:	0800                	addi	s0,sp,16
  int tickets = 1;
#ifdef LBS
  argint(0, &tickets);
#endif
  return tickets;
}
    8000344c:	4505                	li	a0,1
    8000344e:	6422                	ld	s0,8(sp)
    80003450:	0141                	addi	sp,sp,16
    80003452:	8082                	ret

0000000080003454 <sys_set_priority>:

uint64
sys_set_priority(void)
{
    80003454:	1101                	addi	sp,sp,-32
    80003456:	ec06                	sd	ra,24(sp)
    80003458:	e822                	sd	s0,16(sp)
    8000345a:	1000                	addi	s0,sp,32
  int priority;
  int pid;

  argint(0, &priority);
    8000345c:	fec40593          	addi	a1,s0,-20
    80003460:	4501                	li	a0,0
    80003462:	00000097          	auipc	ra,0x0
    80003466:	b30080e7          	jalr	-1232(ra) # 80002f92 <argint>
  argint(1, &pid);
    8000346a:	fe840593          	addi	a1,s0,-24
    8000346e:	4505                	li	a0,1
    80003470:	00000097          	auipc	ra,0x0
    80003474:	b22080e7          	jalr	-1246(ra) # 80002f92 <argint>

  return set_priority(priority, pid);
    80003478:	fe842583          	lw	a1,-24(s0)
    8000347c:	fec42503          	lw	a0,-20(s0)
    80003480:	fffff097          	auipc	ra,0xfffff
    80003484:	e7e080e7          	jalr	-386(ra) # 800022fe <set_priority>
}
    80003488:	60e2                	ld	ra,24(sp)
    8000348a:	6442                	ld	s0,16(sp)
    8000348c:	6105                	addi	sp,sp,32
    8000348e:	8082                	ret

0000000080003490 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003490:	7139                	addi	sp,sp,-64
    80003492:	fc06                	sd	ra,56(sp)
    80003494:	f822                	sd	s0,48(sp)
    80003496:	f426                	sd	s1,40(sp)
    80003498:	f04a                	sd	s2,32(sp)
    8000349a:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    8000349c:	fd840593          	addi	a1,s0,-40
    800034a0:	4501                	li	a0,0
    800034a2:	00000097          	auipc	ra,0x0
    800034a6:	b10080e7          	jalr	-1264(ra) # 80002fb2 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    800034aa:	fd040593          	addi	a1,s0,-48
    800034ae:	4505                	li	a0,1
    800034b0:	00000097          	auipc	ra,0x0
    800034b4:	b02080e7          	jalr	-1278(ra) # 80002fb2 <argaddr>
  argaddr(2, &addr2);
    800034b8:	fc840593          	addi	a1,s0,-56
    800034bc:	4509                	li	a0,2
    800034be:	00000097          	auipc	ra,0x0
    800034c2:	af4080e7          	jalr	-1292(ra) # 80002fb2 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    800034c6:	fc040613          	addi	a2,s0,-64
    800034ca:	fc440593          	addi	a1,s0,-60
    800034ce:	fd843503          	ld	a0,-40(s0)
    800034d2:	fffff097          	auipc	ra,0xfffff
    800034d6:	f18080e7          	jalr	-232(ra) # 800023ea <waitx>
    800034da:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800034dc:	ffffe097          	auipc	ra,0xffffe
    800034e0:	4ea080e7          	jalr	1258(ra) # 800019c6 <myproc>
    800034e4:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800034e6:	4691                	li	a3,4
    800034e8:	fc440613          	addi	a2,s0,-60
    800034ec:	fd043583          	ld	a1,-48(s0)
    800034f0:	6928                	ld	a0,80(a0)
    800034f2:	ffffe097          	auipc	ra,0xffffe
    800034f6:	192080e7          	jalr	402(ra) # 80001684 <copyout>
    return -1;
    800034fa:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800034fc:	00054f63          	bltz	a0,8000351a <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    80003500:	4691                	li	a3,4
    80003502:	fc040613          	addi	a2,s0,-64
    80003506:	fc843583          	ld	a1,-56(s0)
    8000350a:	68a8                	ld	a0,80(s1)
    8000350c:	ffffe097          	auipc	ra,0xffffe
    80003510:	178080e7          	jalr	376(ra) # 80001684 <copyout>
    80003514:	00054a63          	bltz	a0,80003528 <sys_waitx+0x98>
    return -1;
  return ret;
    80003518:	87ca                	mv	a5,s2
    8000351a:	853e                	mv	a0,a5
    8000351c:	70e2                	ld	ra,56(sp)
    8000351e:	7442                	ld	s0,48(sp)
    80003520:	74a2                	ld	s1,40(sp)
    80003522:	7902                	ld	s2,32(sp)
    80003524:	6121                	addi	sp,sp,64
    80003526:	8082                	ret
    return -1;
    80003528:	57fd                	li	a5,-1
    8000352a:	bfc5                	j	8000351a <sys_waitx+0x8a>

000000008000352c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000352c:	7179                	addi	sp,sp,-48
    8000352e:	f406                	sd	ra,40(sp)
    80003530:	f022                	sd	s0,32(sp)
    80003532:	ec26                	sd	s1,24(sp)
    80003534:	e84a                	sd	s2,16(sp)
    80003536:	e44e                	sd	s3,8(sp)
    80003538:	e052                	sd	s4,0(sp)
    8000353a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000353c:	00005597          	auipc	a1,0x5
    80003540:	11c58593          	addi	a1,a1,284 # 80008658 <syscalls+0xe0>
    80003544:	00014517          	auipc	a0,0x14
    80003548:	70450513          	addi	a0,a0,1796 # 80017c48 <bcache>
    8000354c:	ffffd097          	auipc	ra,0xffffd
    80003550:	60e080e7          	jalr	1550(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003554:	0001c797          	auipc	a5,0x1c
    80003558:	6f478793          	addi	a5,a5,1780 # 8001fc48 <bcache+0x8000>
    8000355c:	0001d717          	auipc	a4,0x1d
    80003560:	95470713          	addi	a4,a4,-1708 # 8001feb0 <bcache+0x8268>
    80003564:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003568:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000356c:	00014497          	auipc	s1,0x14
    80003570:	6f448493          	addi	s1,s1,1780 # 80017c60 <bcache+0x18>
    b->next = bcache.head.next;
    80003574:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003576:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003578:	00005a17          	auipc	s4,0x5
    8000357c:	0e8a0a13          	addi	s4,s4,232 # 80008660 <syscalls+0xe8>
    b->next = bcache.head.next;
    80003580:	2b893783          	ld	a5,696(s2)
    80003584:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003586:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000358a:	85d2                	mv	a1,s4
    8000358c:	01048513          	addi	a0,s1,16
    80003590:	00001097          	auipc	ra,0x1
    80003594:	4c4080e7          	jalr	1220(ra) # 80004a54 <initsleeplock>
    bcache.head.next->prev = b;
    80003598:	2b893783          	ld	a5,696(s2)
    8000359c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000359e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800035a2:	45848493          	addi	s1,s1,1112
    800035a6:	fd349de3          	bne	s1,s3,80003580 <binit+0x54>
  }
}
    800035aa:	70a2                	ld	ra,40(sp)
    800035ac:	7402                	ld	s0,32(sp)
    800035ae:	64e2                	ld	s1,24(sp)
    800035b0:	6942                	ld	s2,16(sp)
    800035b2:	69a2                	ld	s3,8(sp)
    800035b4:	6a02                	ld	s4,0(sp)
    800035b6:	6145                	addi	sp,sp,48
    800035b8:	8082                	ret

00000000800035ba <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800035ba:	7179                	addi	sp,sp,-48
    800035bc:	f406                	sd	ra,40(sp)
    800035be:	f022                	sd	s0,32(sp)
    800035c0:	ec26                	sd	s1,24(sp)
    800035c2:	e84a                	sd	s2,16(sp)
    800035c4:	e44e                	sd	s3,8(sp)
    800035c6:	1800                	addi	s0,sp,48
    800035c8:	89aa                	mv	s3,a0
    800035ca:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800035cc:	00014517          	auipc	a0,0x14
    800035d0:	67c50513          	addi	a0,a0,1660 # 80017c48 <bcache>
    800035d4:	ffffd097          	auipc	ra,0xffffd
    800035d8:	616080e7          	jalr	1558(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800035dc:	0001d497          	auipc	s1,0x1d
    800035e0:	9244b483          	ld	s1,-1756(s1) # 8001ff00 <bcache+0x82b8>
    800035e4:	0001d797          	auipc	a5,0x1d
    800035e8:	8cc78793          	addi	a5,a5,-1844 # 8001feb0 <bcache+0x8268>
    800035ec:	02f48f63          	beq	s1,a5,8000362a <bread+0x70>
    800035f0:	873e                	mv	a4,a5
    800035f2:	a021                	j	800035fa <bread+0x40>
    800035f4:	68a4                	ld	s1,80(s1)
    800035f6:	02e48a63          	beq	s1,a4,8000362a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800035fa:	449c                	lw	a5,8(s1)
    800035fc:	ff379ce3          	bne	a5,s3,800035f4 <bread+0x3a>
    80003600:	44dc                	lw	a5,12(s1)
    80003602:	ff2799e3          	bne	a5,s2,800035f4 <bread+0x3a>
      b->refcnt++;
    80003606:	40bc                	lw	a5,64(s1)
    80003608:	2785                	addiw	a5,a5,1
    8000360a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000360c:	00014517          	auipc	a0,0x14
    80003610:	63c50513          	addi	a0,a0,1596 # 80017c48 <bcache>
    80003614:	ffffd097          	auipc	ra,0xffffd
    80003618:	68a080e7          	jalr	1674(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    8000361c:	01048513          	addi	a0,s1,16
    80003620:	00001097          	auipc	ra,0x1
    80003624:	46e080e7          	jalr	1134(ra) # 80004a8e <acquiresleep>
      return b;
    80003628:	a8b9                	j	80003686 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000362a:	0001d497          	auipc	s1,0x1d
    8000362e:	8ce4b483          	ld	s1,-1842(s1) # 8001fef8 <bcache+0x82b0>
    80003632:	0001d797          	auipc	a5,0x1d
    80003636:	87e78793          	addi	a5,a5,-1922 # 8001feb0 <bcache+0x8268>
    8000363a:	00f48863          	beq	s1,a5,8000364a <bread+0x90>
    8000363e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003640:	40bc                	lw	a5,64(s1)
    80003642:	cf81                	beqz	a5,8000365a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003644:	64a4                	ld	s1,72(s1)
    80003646:	fee49de3          	bne	s1,a4,80003640 <bread+0x86>
  panic("bget: no buffers");
    8000364a:	00005517          	auipc	a0,0x5
    8000364e:	01e50513          	addi	a0,a0,30 # 80008668 <syscalls+0xf0>
    80003652:	ffffd097          	auipc	ra,0xffffd
    80003656:	ef2080e7          	jalr	-270(ra) # 80000544 <panic>
      b->dev = dev;
    8000365a:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000365e:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003662:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003666:	4785                	li	a5,1
    80003668:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000366a:	00014517          	auipc	a0,0x14
    8000366e:	5de50513          	addi	a0,a0,1502 # 80017c48 <bcache>
    80003672:	ffffd097          	auipc	ra,0xffffd
    80003676:	62c080e7          	jalr	1580(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    8000367a:	01048513          	addi	a0,s1,16
    8000367e:	00001097          	auipc	ra,0x1
    80003682:	410080e7          	jalr	1040(ra) # 80004a8e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003686:	409c                	lw	a5,0(s1)
    80003688:	cb89                	beqz	a5,8000369a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000368a:	8526                	mv	a0,s1
    8000368c:	70a2                	ld	ra,40(sp)
    8000368e:	7402                	ld	s0,32(sp)
    80003690:	64e2                	ld	s1,24(sp)
    80003692:	6942                	ld	s2,16(sp)
    80003694:	69a2                	ld	s3,8(sp)
    80003696:	6145                	addi	sp,sp,48
    80003698:	8082                	ret
    virtio_disk_rw(b, 0);
    8000369a:	4581                	li	a1,0
    8000369c:	8526                	mv	a0,s1
    8000369e:	00003097          	auipc	ra,0x3
    800036a2:	fca080e7          	jalr	-54(ra) # 80006668 <virtio_disk_rw>
    b->valid = 1;
    800036a6:	4785                	li	a5,1
    800036a8:	c09c                	sw	a5,0(s1)
  return b;
    800036aa:	b7c5                	j	8000368a <bread+0xd0>

00000000800036ac <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800036ac:	1101                	addi	sp,sp,-32
    800036ae:	ec06                	sd	ra,24(sp)
    800036b0:	e822                	sd	s0,16(sp)
    800036b2:	e426                	sd	s1,8(sp)
    800036b4:	1000                	addi	s0,sp,32
    800036b6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800036b8:	0541                	addi	a0,a0,16
    800036ba:	00001097          	auipc	ra,0x1
    800036be:	46e080e7          	jalr	1134(ra) # 80004b28 <holdingsleep>
    800036c2:	cd01                	beqz	a0,800036da <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800036c4:	4585                	li	a1,1
    800036c6:	8526                	mv	a0,s1
    800036c8:	00003097          	auipc	ra,0x3
    800036cc:	fa0080e7          	jalr	-96(ra) # 80006668 <virtio_disk_rw>
}
    800036d0:	60e2                	ld	ra,24(sp)
    800036d2:	6442                	ld	s0,16(sp)
    800036d4:	64a2                	ld	s1,8(sp)
    800036d6:	6105                	addi	sp,sp,32
    800036d8:	8082                	ret
    panic("bwrite");
    800036da:	00005517          	auipc	a0,0x5
    800036de:	fa650513          	addi	a0,a0,-90 # 80008680 <syscalls+0x108>
    800036e2:	ffffd097          	auipc	ra,0xffffd
    800036e6:	e62080e7          	jalr	-414(ra) # 80000544 <panic>

00000000800036ea <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800036ea:	1101                	addi	sp,sp,-32
    800036ec:	ec06                	sd	ra,24(sp)
    800036ee:	e822                	sd	s0,16(sp)
    800036f0:	e426                	sd	s1,8(sp)
    800036f2:	e04a                	sd	s2,0(sp)
    800036f4:	1000                	addi	s0,sp,32
    800036f6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800036f8:	01050913          	addi	s2,a0,16
    800036fc:	854a                	mv	a0,s2
    800036fe:	00001097          	auipc	ra,0x1
    80003702:	42a080e7          	jalr	1066(ra) # 80004b28 <holdingsleep>
    80003706:	c92d                	beqz	a0,80003778 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003708:	854a                	mv	a0,s2
    8000370a:	00001097          	auipc	ra,0x1
    8000370e:	3da080e7          	jalr	986(ra) # 80004ae4 <releasesleep>

  acquire(&bcache.lock);
    80003712:	00014517          	auipc	a0,0x14
    80003716:	53650513          	addi	a0,a0,1334 # 80017c48 <bcache>
    8000371a:	ffffd097          	auipc	ra,0xffffd
    8000371e:	4d0080e7          	jalr	1232(ra) # 80000bea <acquire>
  b->refcnt--;
    80003722:	40bc                	lw	a5,64(s1)
    80003724:	37fd                	addiw	a5,a5,-1
    80003726:	0007871b          	sext.w	a4,a5
    8000372a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000372c:	eb05                	bnez	a4,8000375c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000372e:	68bc                	ld	a5,80(s1)
    80003730:	64b8                	ld	a4,72(s1)
    80003732:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003734:	64bc                	ld	a5,72(s1)
    80003736:	68b8                	ld	a4,80(s1)
    80003738:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000373a:	0001c797          	auipc	a5,0x1c
    8000373e:	50e78793          	addi	a5,a5,1294 # 8001fc48 <bcache+0x8000>
    80003742:	2b87b703          	ld	a4,696(a5)
    80003746:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003748:	0001c717          	auipc	a4,0x1c
    8000374c:	76870713          	addi	a4,a4,1896 # 8001feb0 <bcache+0x8268>
    80003750:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003752:	2b87b703          	ld	a4,696(a5)
    80003756:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003758:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000375c:	00014517          	auipc	a0,0x14
    80003760:	4ec50513          	addi	a0,a0,1260 # 80017c48 <bcache>
    80003764:	ffffd097          	auipc	ra,0xffffd
    80003768:	53a080e7          	jalr	1338(ra) # 80000c9e <release>
}
    8000376c:	60e2                	ld	ra,24(sp)
    8000376e:	6442                	ld	s0,16(sp)
    80003770:	64a2                	ld	s1,8(sp)
    80003772:	6902                	ld	s2,0(sp)
    80003774:	6105                	addi	sp,sp,32
    80003776:	8082                	ret
    panic("brelse");
    80003778:	00005517          	auipc	a0,0x5
    8000377c:	f1050513          	addi	a0,a0,-240 # 80008688 <syscalls+0x110>
    80003780:	ffffd097          	auipc	ra,0xffffd
    80003784:	dc4080e7          	jalr	-572(ra) # 80000544 <panic>

0000000080003788 <bpin>:

void
bpin(struct buf *b) {
    80003788:	1101                	addi	sp,sp,-32
    8000378a:	ec06                	sd	ra,24(sp)
    8000378c:	e822                	sd	s0,16(sp)
    8000378e:	e426                	sd	s1,8(sp)
    80003790:	1000                	addi	s0,sp,32
    80003792:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003794:	00014517          	auipc	a0,0x14
    80003798:	4b450513          	addi	a0,a0,1204 # 80017c48 <bcache>
    8000379c:	ffffd097          	auipc	ra,0xffffd
    800037a0:	44e080e7          	jalr	1102(ra) # 80000bea <acquire>
  b->refcnt++;
    800037a4:	40bc                	lw	a5,64(s1)
    800037a6:	2785                	addiw	a5,a5,1
    800037a8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800037aa:	00014517          	auipc	a0,0x14
    800037ae:	49e50513          	addi	a0,a0,1182 # 80017c48 <bcache>
    800037b2:	ffffd097          	auipc	ra,0xffffd
    800037b6:	4ec080e7          	jalr	1260(ra) # 80000c9e <release>
}
    800037ba:	60e2                	ld	ra,24(sp)
    800037bc:	6442                	ld	s0,16(sp)
    800037be:	64a2                	ld	s1,8(sp)
    800037c0:	6105                	addi	sp,sp,32
    800037c2:	8082                	ret

00000000800037c4 <bunpin>:

void
bunpin(struct buf *b) {
    800037c4:	1101                	addi	sp,sp,-32
    800037c6:	ec06                	sd	ra,24(sp)
    800037c8:	e822                	sd	s0,16(sp)
    800037ca:	e426                	sd	s1,8(sp)
    800037cc:	1000                	addi	s0,sp,32
    800037ce:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037d0:	00014517          	auipc	a0,0x14
    800037d4:	47850513          	addi	a0,a0,1144 # 80017c48 <bcache>
    800037d8:	ffffd097          	auipc	ra,0xffffd
    800037dc:	412080e7          	jalr	1042(ra) # 80000bea <acquire>
  b->refcnt--;
    800037e0:	40bc                	lw	a5,64(s1)
    800037e2:	37fd                	addiw	a5,a5,-1
    800037e4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800037e6:	00014517          	auipc	a0,0x14
    800037ea:	46250513          	addi	a0,a0,1122 # 80017c48 <bcache>
    800037ee:	ffffd097          	auipc	ra,0xffffd
    800037f2:	4b0080e7          	jalr	1200(ra) # 80000c9e <release>
}
    800037f6:	60e2                	ld	ra,24(sp)
    800037f8:	6442                	ld	s0,16(sp)
    800037fa:	64a2                	ld	s1,8(sp)
    800037fc:	6105                	addi	sp,sp,32
    800037fe:	8082                	ret

0000000080003800 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003800:	1101                	addi	sp,sp,-32
    80003802:	ec06                	sd	ra,24(sp)
    80003804:	e822                	sd	s0,16(sp)
    80003806:	e426                	sd	s1,8(sp)
    80003808:	e04a                	sd	s2,0(sp)
    8000380a:	1000                	addi	s0,sp,32
    8000380c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000380e:	00d5d59b          	srliw	a1,a1,0xd
    80003812:	0001d797          	auipc	a5,0x1d
    80003816:	b127a783          	lw	a5,-1262(a5) # 80020324 <sb+0x1c>
    8000381a:	9dbd                	addw	a1,a1,a5
    8000381c:	00000097          	auipc	ra,0x0
    80003820:	d9e080e7          	jalr	-610(ra) # 800035ba <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003824:	0074f713          	andi	a4,s1,7
    80003828:	4785                	li	a5,1
    8000382a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000382e:	14ce                	slli	s1,s1,0x33
    80003830:	90d9                	srli	s1,s1,0x36
    80003832:	00950733          	add	a4,a0,s1
    80003836:	05874703          	lbu	a4,88(a4)
    8000383a:	00e7f6b3          	and	a3,a5,a4
    8000383e:	c69d                	beqz	a3,8000386c <bfree+0x6c>
    80003840:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003842:	94aa                	add	s1,s1,a0
    80003844:	fff7c793          	not	a5,a5
    80003848:	8ff9                	and	a5,a5,a4
    8000384a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000384e:	00001097          	auipc	ra,0x1
    80003852:	120080e7          	jalr	288(ra) # 8000496e <log_write>
  brelse(bp);
    80003856:	854a                	mv	a0,s2
    80003858:	00000097          	auipc	ra,0x0
    8000385c:	e92080e7          	jalr	-366(ra) # 800036ea <brelse>
}
    80003860:	60e2                	ld	ra,24(sp)
    80003862:	6442                	ld	s0,16(sp)
    80003864:	64a2                	ld	s1,8(sp)
    80003866:	6902                	ld	s2,0(sp)
    80003868:	6105                	addi	sp,sp,32
    8000386a:	8082                	ret
    panic("freeing free block");
    8000386c:	00005517          	auipc	a0,0x5
    80003870:	e2450513          	addi	a0,a0,-476 # 80008690 <syscalls+0x118>
    80003874:	ffffd097          	auipc	ra,0xffffd
    80003878:	cd0080e7          	jalr	-816(ra) # 80000544 <panic>

000000008000387c <balloc>:
{
    8000387c:	711d                	addi	sp,sp,-96
    8000387e:	ec86                	sd	ra,88(sp)
    80003880:	e8a2                	sd	s0,80(sp)
    80003882:	e4a6                	sd	s1,72(sp)
    80003884:	e0ca                	sd	s2,64(sp)
    80003886:	fc4e                	sd	s3,56(sp)
    80003888:	f852                	sd	s4,48(sp)
    8000388a:	f456                	sd	s5,40(sp)
    8000388c:	f05a                	sd	s6,32(sp)
    8000388e:	ec5e                	sd	s7,24(sp)
    80003890:	e862                	sd	s8,16(sp)
    80003892:	e466                	sd	s9,8(sp)
    80003894:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003896:	0001d797          	auipc	a5,0x1d
    8000389a:	a767a783          	lw	a5,-1418(a5) # 8002030c <sb+0x4>
    8000389e:	10078163          	beqz	a5,800039a0 <balloc+0x124>
    800038a2:	8baa                	mv	s7,a0
    800038a4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800038a6:	0001db17          	auipc	s6,0x1d
    800038aa:	a62b0b13          	addi	s6,s6,-1438 # 80020308 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038ae:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800038b0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038b2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800038b4:	6c89                	lui	s9,0x2
    800038b6:	a061                	j	8000393e <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    800038b8:	974a                	add	a4,a4,s2
    800038ba:	8fd5                	or	a5,a5,a3
    800038bc:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800038c0:	854a                	mv	a0,s2
    800038c2:	00001097          	auipc	ra,0x1
    800038c6:	0ac080e7          	jalr	172(ra) # 8000496e <log_write>
        brelse(bp);
    800038ca:	854a                	mv	a0,s2
    800038cc:	00000097          	auipc	ra,0x0
    800038d0:	e1e080e7          	jalr	-482(ra) # 800036ea <brelse>
  bp = bread(dev, bno);
    800038d4:	85a6                	mv	a1,s1
    800038d6:	855e                	mv	a0,s7
    800038d8:	00000097          	auipc	ra,0x0
    800038dc:	ce2080e7          	jalr	-798(ra) # 800035ba <bread>
    800038e0:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800038e2:	40000613          	li	a2,1024
    800038e6:	4581                	li	a1,0
    800038e8:	05850513          	addi	a0,a0,88
    800038ec:	ffffd097          	auipc	ra,0xffffd
    800038f0:	3fa080e7          	jalr	1018(ra) # 80000ce6 <memset>
  log_write(bp);
    800038f4:	854a                	mv	a0,s2
    800038f6:	00001097          	auipc	ra,0x1
    800038fa:	078080e7          	jalr	120(ra) # 8000496e <log_write>
  brelse(bp);
    800038fe:	854a                	mv	a0,s2
    80003900:	00000097          	auipc	ra,0x0
    80003904:	dea080e7          	jalr	-534(ra) # 800036ea <brelse>
}
    80003908:	8526                	mv	a0,s1
    8000390a:	60e6                	ld	ra,88(sp)
    8000390c:	6446                	ld	s0,80(sp)
    8000390e:	64a6                	ld	s1,72(sp)
    80003910:	6906                	ld	s2,64(sp)
    80003912:	79e2                	ld	s3,56(sp)
    80003914:	7a42                	ld	s4,48(sp)
    80003916:	7aa2                	ld	s5,40(sp)
    80003918:	7b02                	ld	s6,32(sp)
    8000391a:	6be2                	ld	s7,24(sp)
    8000391c:	6c42                	ld	s8,16(sp)
    8000391e:	6ca2                	ld	s9,8(sp)
    80003920:	6125                	addi	sp,sp,96
    80003922:	8082                	ret
    brelse(bp);
    80003924:	854a                	mv	a0,s2
    80003926:	00000097          	auipc	ra,0x0
    8000392a:	dc4080e7          	jalr	-572(ra) # 800036ea <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000392e:	015c87bb          	addw	a5,s9,s5
    80003932:	00078a9b          	sext.w	s5,a5
    80003936:	004b2703          	lw	a4,4(s6)
    8000393a:	06eaf363          	bgeu	s5,a4,800039a0 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    8000393e:	41fad79b          	sraiw	a5,s5,0x1f
    80003942:	0137d79b          	srliw	a5,a5,0x13
    80003946:	015787bb          	addw	a5,a5,s5
    8000394a:	40d7d79b          	sraiw	a5,a5,0xd
    8000394e:	01cb2583          	lw	a1,28(s6)
    80003952:	9dbd                	addw	a1,a1,a5
    80003954:	855e                	mv	a0,s7
    80003956:	00000097          	auipc	ra,0x0
    8000395a:	c64080e7          	jalr	-924(ra) # 800035ba <bread>
    8000395e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003960:	004b2503          	lw	a0,4(s6)
    80003964:	000a849b          	sext.w	s1,s5
    80003968:	8662                	mv	a2,s8
    8000396a:	faa4fde3          	bgeu	s1,a0,80003924 <balloc+0xa8>
      m = 1 << (bi % 8);
    8000396e:	41f6579b          	sraiw	a5,a2,0x1f
    80003972:	01d7d69b          	srliw	a3,a5,0x1d
    80003976:	00c6873b          	addw	a4,a3,a2
    8000397a:	00777793          	andi	a5,a4,7
    8000397e:	9f95                	subw	a5,a5,a3
    80003980:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003984:	4037571b          	sraiw	a4,a4,0x3
    80003988:	00e906b3          	add	a3,s2,a4
    8000398c:	0586c683          	lbu	a3,88(a3)
    80003990:	00d7f5b3          	and	a1,a5,a3
    80003994:	d195                	beqz	a1,800038b8 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003996:	2605                	addiw	a2,a2,1
    80003998:	2485                	addiw	s1,s1,1
    8000399a:	fd4618e3          	bne	a2,s4,8000396a <balloc+0xee>
    8000399e:	b759                	j	80003924 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    800039a0:	00005517          	auipc	a0,0x5
    800039a4:	d0850513          	addi	a0,a0,-760 # 800086a8 <syscalls+0x130>
    800039a8:	ffffd097          	auipc	ra,0xffffd
    800039ac:	be6080e7          	jalr	-1050(ra) # 8000058e <printf>
  return 0;
    800039b0:	4481                	li	s1,0
    800039b2:	bf99                	j	80003908 <balloc+0x8c>

00000000800039b4 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800039b4:	7179                	addi	sp,sp,-48
    800039b6:	f406                	sd	ra,40(sp)
    800039b8:	f022                	sd	s0,32(sp)
    800039ba:	ec26                	sd	s1,24(sp)
    800039bc:	e84a                	sd	s2,16(sp)
    800039be:	e44e                	sd	s3,8(sp)
    800039c0:	e052                	sd	s4,0(sp)
    800039c2:	1800                	addi	s0,sp,48
    800039c4:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800039c6:	47ad                	li	a5,11
    800039c8:	02b7e763          	bltu	a5,a1,800039f6 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800039cc:	02059493          	slli	s1,a1,0x20
    800039d0:	9081                	srli	s1,s1,0x20
    800039d2:	048a                	slli	s1,s1,0x2
    800039d4:	94aa                	add	s1,s1,a0
    800039d6:	0504a903          	lw	s2,80(s1)
    800039da:	06091e63          	bnez	s2,80003a56 <bmap+0xa2>
      addr = balloc(ip->dev);
    800039de:	4108                	lw	a0,0(a0)
    800039e0:	00000097          	auipc	ra,0x0
    800039e4:	e9c080e7          	jalr	-356(ra) # 8000387c <balloc>
    800039e8:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800039ec:	06090563          	beqz	s2,80003a56 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800039f0:	0524a823          	sw	s2,80(s1)
    800039f4:	a08d                	j	80003a56 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800039f6:	ff45849b          	addiw	s1,a1,-12
    800039fa:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800039fe:	0ff00793          	li	a5,255
    80003a02:	08e7e563          	bltu	a5,a4,80003a8c <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003a06:	08052903          	lw	s2,128(a0)
    80003a0a:	00091d63          	bnez	s2,80003a24 <bmap+0x70>
      addr = balloc(ip->dev);
    80003a0e:	4108                	lw	a0,0(a0)
    80003a10:	00000097          	auipc	ra,0x0
    80003a14:	e6c080e7          	jalr	-404(ra) # 8000387c <balloc>
    80003a18:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003a1c:	02090d63          	beqz	s2,80003a56 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003a20:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003a24:	85ca                	mv	a1,s2
    80003a26:	0009a503          	lw	a0,0(s3)
    80003a2a:	00000097          	auipc	ra,0x0
    80003a2e:	b90080e7          	jalr	-1136(ra) # 800035ba <bread>
    80003a32:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003a34:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003a38:	02049593          	slli	a1,s1,0x20
    80003a3c:	9181                	srli	a1,a1,0x20
    80003a3e:	058a                	slli	a1,a1,0x2
    80003a40:	00b784b3          	add	s1,a5,a1
    80003a44:	0004a903          	lw	s2,0(s1)
    80003a48:	02090063          	beqz	s2,80003a68 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003a4c:	8552                	mv	a0,s4
    80003a4e:	00000097          	auipc	ra,0x0
    80003a52:	c9c080e7          	jalr	-868(ra) # 800036ea <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003a56:	854a                	mv	a0,s2
    80003a58:	70a2                	ld	ra,40(sp)
    80003a5a:	7402                	ld	s0,32(sp)
    80003a5c:	64e2                	ld	s1,24(sp)
    80003a5e:	6942                	ld	s2,16(sp)
    80003a60:	69a2                	ld	s3,8(sp)
    80003a62:	6a02                	ld	s4,0(sp)
    80003a64:	6145                	addi	sp,sp,48
    80003a66:	8082                	ret
      addr = balloc(ip->dev);
    80003a68:	0009a503          	lw	a0,0(s3)
    80003a6c:	00000097          	auipc	ra,0x0
    80003a70:	e10080e7          	jalr	-496(ra) # 8000387c <balloc>
    80003a74:	0005091b          	sext.w	s2,a0
      if(addr){
    80003a78:	fc090ae3          	beqz	s2,80003a4c <bmap+0x98>
        a[bn] = addr;
    80003a7c:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003a80:	8552                	mv	a0,s4
    80003a82:	00001097          	auipc	ra,0x1
    80003a86:	eec080e7          	jalr	-276(ra) # 8000496e <log_write>
    80003a8a:	b7c9                	j	80003a4c <bmap+0x98>
  panic("bmap: out of range");
    80003a8c:	00005517          	auipc	a0,0x5
    80003a90:	c3450513          	addi	a0,a0,-972 # 800086c0 <syscalls+0x148>
    80003a94:	ffffd097          	auipc	ra,0xffffd
    80003a98:	ab0080e7          	jalr	-1360(ra) # 80000544 <panic>

0000000080003a9c <iget>:
{
    80003a9c:	7179                	addi	sp,sp,-48
    80003a9e:	f406                	sd	ra,40(sp)
    80003aa0:	f022                	sd	s0,32(sp)
    80003aa2:	ec26                	sd	s1,24(sp)
    80003aa4:	e84a                	sd	s2,16(sp)
    80003aa6:	e44e                	sd	s3,8(sp)
    80003aa8:	e052                	sd	s4,0(sp)
    80003aaa:	1800                	addi	s0,sp,48
    80003aac:	89aa                	mv	s3,a0
    80003aae:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003ab0:	0001d517          	auipc	a0,0x1d
    80003ab4:	87850513          	addi	a0,a0,-1928 # 80020328 <itable>
    80003ab8:	ffffd097          	auipc	ra,0xffffd
    80003abc:	132080e7          	jalr	306(ra) # 80000bea <acquire>
  empty = 0;
    80003ac0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003ac2:	0001d497          	auipc	s1,0x1d
    80003ac6:	87e48493          	addi	s1,s1,-1922 # 80020340 <itable+0x18>
    80003aca:	0001e697          	auipc	a3,0x1e
    80003ace:	30668693          	addi	a3,a3,774 # 80021dd0 <log>
    80003ad2:	a039                	j	80003ae0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003ad4:	02090b63          	beqz	s2,80003b0a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003ad8:	08848493          	addi	s1,s1,136
    80003adc:	02d48a63          	beq	s1,a3,80003b10 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003ae0:	449c                	lw	a5,8(s1)
    80003ae2:	fef059e3          	blez	a5,80003ad4 <iget+0x38>
    80003ae6:	4098                	lw	a4,0(s1)
    80003ae8:	ff3716e3          	bne	a4,s3,80003ad4 <iget+0x38>
    80003aec:	40d8                	lw	a4,4(s1)
    80003aee:	ff4713e3          	bne	a4,s4,80003ad4 <iget+0x38>
      ip->ref++;
    80003af2:	2785                	addiw	a5,a5,1
    80003af4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003af6:	0001d517          	auipc	a0,0x1d
    80003afa:	83250513          	addi	a0,a0,-1998 # 80020328 <itable>
    80003afe:	ffffd097          	auipc	ra,0xffffd
    80003b02:	1a0080e7          	jalr	416(ra) # 80000c9e <release>
      return ip;
    80003b06:	8926                	mv	s2,s1
    80003b08:	a03d                	j	80003b36 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b0a:	f7f9                	bnez	a5,80003ad8 <iget+0x3c>
    80003b0c:	8926                	mv	s2,s1
    80003b0e:	b7e9                	j	80003ad8 <iget+0x3c>
  if(empty == 0)
    80003b10:	02090c63          	beqz	s2,80003b48 <iget+0xac>
  ip->dev = dev;
    80003b14:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003b18:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003b1c:	4785                	li	a5,1
    80003b1e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003b22:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003b26:	0001d517          	auipc	a0,0x1d
    80003b2a:	80250513          	addi	a0,a0,-2046 # 80020328 <itable>
    80003b2e:	ffffd097          	auipc	ra,0xffffd
    80003b32:	170080e7          	jalr	368(ra) # 80000c9e <release>
}
    80003b36:	854a                	mv	a0,s2
    80003b38:	70a2                	ld	ra,40(sp)
    80003b3a:	7402                	ld	s0,32(sp)
    80003b3c:	64e2                	ld	s1,24(sp)
    80003b3e:	6942                	ld	s2,16(sp)
    80003b40:	69a2                	ld	s3,8(sp)
    80003b42:	6a02                	ld	s4,0(sp)
    80003b44:	6145                	addi	sp,sp,48
    80003b46:	8082                	ret
    panic("iget: no inodes");
    80003b48:	00005517          	auipc	a0,0x5
    80003b4c:	b9050513          	addi	a0,a0,-1136 # 800086d8 <syscalls+0x160>
    80003b50:	ffffd097          	auipc	ra,0xffffd
    80003b54:	9f4080e7          	jalr	-1548(ra) # 80000544 <panic>

0000000080003b58 <fsinit>:
fsinit(int dev) {
    80003b58:	7179                	addi	sp,sp,-48
    80003b5a:	f406                	sd	ra,40(sp)
    80003b5c:	f022                	sd	s0,32(sp)
    80003b5e:	ec26                	sd	s1,24(sp)
    80003b60:	e84a                	sd	s2,16(sp)
    80003b62:	e44e                	sd	s3,8(sp)
    80003b64:	1800                	addi	s0,sp,48
    80003b66:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003b68:	4585                	li	a1,1
    80003b6a:	00000097          	auipc	ra,0x0
    80003b6e:	a50080e7          	jalr	-1456(ra) # 800035ba <bread>
    80003b72:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003b74:	0001c997          	auipc	s3,0x1c
    80003b78:	79498993          	addi	s3,s3,1940 # 80020308 <sb>
    80003b7c:	02000613          	li	a2,32
    80003b80:	05850593          	addi	a1,a0,88
    80003b84:	854e                	mv	a0,s3
    80003b86:	ffffd097          	auipc	ra,0xffffd
    80003b8a:	1c0080e7          	jalr	448(ra) # 80000d46 <memmove>
  brelse(bp);
    80003b8e:	8526                	mv	a0,s1
    80003b90:	00000097          	auipc	ra,0x0
    80003b94:	b5a080e7          	jalr	-1190(ra) # 800036ea <brelse>
  if(sb.magic != FSMAGIC)
    80003b98:	0009a703          	lw	a4,0(s3)
    80003b9c:	102037b7          	lui	a5,0x10203
    80003ba0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003ba4:	02f71263          	bne	a4,a5,80003bc8 <fsinit+0x70>
  initlog(dev, &sb);
    80003ba8:	0001c597          	auipc	a1,0x1c
    80003bac:	76058593          	addi	a1,a1,1888 # 80020308 <sb>
    80003bb0:	854a                	mv	a0,s2
    80003bb2:	00001097          	auipc	ra,0x1
    80003bb6:	b40080e7          	jalr	-1216(ra) # 800046f2 <initlog>
}
    80003bba:	70a2                	ld	ra,40(sp)
    80003bbc:	7402                	ld	s0,32(sp)
    80003bbe:	64e2                	ld	s1,24(sp)
    80003bc0:	6942                	ld	s2,16(sp)
    80003bc2:	69a2                	ld	s3,8(sp)
    80003bc4:	6145                	addi	sp,sp,48
    80003bc6:	8082                	ret
    panic("invalid file system");
    80003bc8:	00005517          	auipc	a0,0x5
    80003bcc:	b2050513          	addi	a0,a0,-1248 # 800086e8 <syscalls+0x170>
    80003bd0:	ffffd097          	auipc	ra,0xffffd
    80003bd4:	974080e7          	jalr	-1676(ra) # 80000544 <panic>

0000000080003bd8 <iinit>:
{
    80003bd8:	7179                	addi	sp,sp,-48
    80003bda:	f406                	sd	ra,40(sp)
    80003bdc:	f022                	sd	s0,32(sp)
    80003bde:	ec26                	sd	s1,24(sp)
    80003be0:	e84a                	sd	s2,16(sp)
    80003be2:	e44e                	sd	s3,8(sp)
    80003be4:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003be6:	00005597          	auipc	a1,0x5
    80003bea:	b1a58593          	addi	a1,a1,-1254 # 80008700 <syscalls+0x188>
    80003bee:	0001c517          	auipc	a0,0x1c
    80003bf2:	73a50513          	addi	a0,a0,1850 # 80020328 <itable>
    80003bf6:	ffffd097          	auipc	ra,0xffffd
    80003bfa:	f64080e7          	jalr	-156(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    80003bfe:	0001c497          	auipc	s1,0x1c
    80003c02:	75248493          	addi	s1,s1,1874 # 80020350 <itable+0x28>
    80003c06:	0001e997          	auipc	s3,0x1e
    80003c0a:	1da98993          	addi	s3,s3,474 # 80021de0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003c0e:	00005917          	auipc	s2,0x5
    80003c12:	afa90913          	addi	s2,s2,-1286 # 80008708 <syscalls+0x190>
    80003c16:	85ca                	mv	a1,s2
    80003c18:	8526                	mv	a0,s1
    80003c1a:	00001097          	auipc	ra,0x1
    80003c1e:	e3a080e7          	jalr	-454(ra) # 80004a54 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003c22:	08848493          	addi	s1,s1,136
    80003c26:	ff3498e3          	bne	s1,s3,80003c16 <iinit+0x3e>
}
    80003c2a:	70a2                	ld	ra,40(sp)
    80003c2c:	7402                	ld	s0,32(sp)
    80003c2e:	64e2                	ld	s1,24(sp)
    80003c30:	6942                	ld	s2,16(sp)
    80003c32:	69a2                	ld	s3,8(sp)
    80003c34:	6145                	addi	sp,sp,48
    80003c36:	8082                	ret

0000000080003c38 <ialloc>:
{
    80003c38:	715d                	addi	sp,sp,-80
    80003c3a:	e486                	sd	ra,72(sp)
    80003c3c:	e0a2                	sd	s0,64(sp)
    80003c3e:	fc26                	sd	s1,56(sp)
    80003c40:	f84a                	sd	s2,48(sp)
    80003c42:	f44e                	sd	s3,40(sp)
    80003c44:	f052                	sd	s4,32(sp)
    80003c46:	ec56                	sd	s5,24(sp)
    80003c48:	e85a                	sd	s6,16(sp)
    80003c4a:	e45e                	sd	s7,8(sp)
    80003c4c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c4e:	0001c717          	auipc	a4,0x1c
    80003c52:	6c672703          	lw	a4,1734(a4) # 80020314 <sb+0xc>
    80003c56:	4785                	li	a5,1
    80003c58:	04e7fa63          	bgeu	a5,a4,80003cac <ialloc+0x74>
    80003c5c:	8aaa                	mv	s5,a0
    80003c5e:	8bae                	mv	s7,a1
    80003c60:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003c62:	0001ca17          	auipc	s4,0x1c
    80003c66:	6a6a0a13          	addi	s4,s4,1702 # 80020308 <sb>
    80003c6a:	00048b1b          	sext.w	s6,s1
    80003c6e:	0044d593          	srli	a1,s1,0x4
    80003c72:	018a2783          	lw	a5,24(s4)
    80003c76:	9dbd                	addw	a1,a1,a5
    80003c78:	8556                	mv	a0,s5
    80003c7a:	00000097          	auipc	ra,0x0
    80003c7e:	940080e7          	jalr	-1728(ra) # 800035ba <bread>
    80003c82:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003c84:	05850993          	addi	s3,a0,88
    80003c88:	00f4f793          	andi	a5,s1,15
    80003c8c:	079a                	slli	a5,a5,0x6
    80003c8e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003c90:	00099783          	lh	a5,0(s3)
    80003c94:	c3a1                	beqz	a5,80003cd4 <ialloc+0x9c>
    brelse(bp);
    80003c96:	00000097          	auipc	ra,0x0
    80003c9a:	a54080e7          	jalr	-1452(ra) # 800036ea <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c9e:	0485                	addi	s1,s1,1
    80003ca0:	00ca2703          	lw	a4,12(s4)
    80003ca4:	0004879b          	sext.w	a5,s1
    80003ca8:	fce7e1e3          	bltu	a5,a4,80003c6a <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003cac:	00005517          	auipc	a0,0x5
    80003cb0:	a6450513          	addi	a0,a0,-1436 # 80008710 <syscalls+0x198>
    80003cb4:	ffffd097          	auipc	ra,0xffffd
    80003cb8:	8da080e7          	jalr	-1830(ra) # 8000058e <printf>
  return 0;
    80003cbc:	4501                	li	a0,0
}
    80003cbe:	60a6                	ld	ra,72(sp)
    80003cc0:	6406                	ld	s0,64(sp)
    80003cc2:	74e2                	ld	s1,56(sp)
    80003cc4:	7942                	ld	s2,48(sp)
    80003cc6:	79a2                	ld	s3,40(sp)
    80003cc8:	7a02                	ld	s4,32(sp)
    80003cca:	6ae2                	ld	s5,24(sp)
    80003ccc:	6b42                	ld	s6,16(sp)
    80003cce:	6ba2                	ld	s7,8(sp)
    80003cd0:	6161                	addi	sp,sp,80
    80003cd2:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003cd4:	04000613          	li	a2,64
    80003cd8:	4581                	li	a1,0
    80003cda:	854e                	mv	a0,s3
    80003cdc:	ffffd097          	auipc	ra,0xffffd
    80003ce0:	00a080e7          	jalr	10(ra) # 80000ce6 <memset>
      dip->type = type;
    80003ce4:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003ce8:	854a                	mv	a0,s2
    80003cea:	00001097          	auipc	ra,0x1
    80003cee:	c84080e7          	jalr	-892(ra) # 8000496e <log_write>
      brelse(bp);
    80003cf2:	854a                	mv	a0,s2
    80003cf4:	00000097          	auipc	ra,0x0
    80003cf8:	9f6080e7          	jalr	-1546(ra) # 800036ea <brelse>
      return iget(dev, inum);
    80003cfc:	85da                	mv	a1,s6
    80003cfe:	8556                	mv	a0,s5
    80003d00:	00000097          	auipc	ra,0x0
    80003d04:	d9c080e7          	jalr	-612(ra) # 80003a9c <iget>
    80003d08:	bf5d                	j	80003cbe <ialloc+0x86>

0000000080003d0a <iupdate>:
{
    80003d0a:	1101                	addi	sp,sp,-32
    80003d0c:	ec06                	sd	ra,24(sp)
    80003d0e:	e822                	sd	s0,16(sp)
    80003d10:	e426                	sd	s1,8(sp)
    80003d12:	e04a                	sd	s2,0(sp)
    80003d14:	1000                	addi	s0,sp,32
    80003d16:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d18:	415c                	lw	a5,4(a0)
    80003d1a:	0047d79b          	srliw	a5,a5,0x4
    80003d1e:	0001c597          	auipc	a1,0x1c
    80003d22:	6025a583          	lw	a1,1538(a1) # 80020320 <sb+0x18>
    80003d26:	9dbd                	addw	a1,a1,a5
    80003d28:	4108                	lw	a0,0(a0)
    80003d2a:	00000097          	auipc	ra,0x0
    80003d2e:	890080e7          	jalr	-1904(ra) # 800035ba <bread>
    80003d32:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d34:	05850793          	addi	a5,a0,88
    80003d38:	40c8                	lw	a0,4(s1)
    80003d3a:	893d                	andi	a0,a0,15
    80003d3c:	051a                	slli	a0,a0,0x6
    80003d3e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003d40:	04449703          	lh	a4,68(s1)
    80003d44:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003d48:	04649703          	lh	a4,70(s1)
    80003d4c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003d50:	04849703          	lh	a4,72(s1)
    80003d54:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003d58:	04a49703          	lh	a4,74(s1)
    80003d5c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003d60:	44f8                	lw	a4,76(s1)
    80003d62:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003d64:	03400613          	li	a2,52
    80003d68:	05048593          	addi	a1,s1,80
    80003d6c:	0531                	addi	a0,a0,12
    80003d6e:	ffffd097          	auipc	ra,0xffffd
    80003d72:	fd8080e7          	jalr	-40(ra) # 80000d46 <memmove>
  log_write(bp);
    80003d76:	854a                	mv	a0,s2
    80003d78:	00001097          	auipc	ra,0x1
    80003d7c:	bf6080e7          	jalr	-1034(ra) # 8000496e <log_write>
  brelse(bp);
    80003d80:	854a                	mv	a0,s2
    80003d82:	00000097          	auipc	ra,0x0
    80003d86:	968080e7          	jalr	-1688(ra) # 800036ea <brelse>
}
    80003d8a:	60e2                	ld	ra,24(sp)
    80003d8c:	6442                	ld	s0,16(sp)
    80003d8e:	64a2                	ld	s1,8(sp)
    80003d90:	6902                	ld	s2,0(sp)
    80003d92:	6105                	addi	sp,sp,32
    80003d94:	8082                	ret

0000000080003d96 <idup>:
{
    80003d96:	1101                	addi	sp,sp,-32
    80003d98:	ec06                	sd	ra,24(sp)
    80003d9a:	e822                	sd	s0,16(sp)
    80003d9c:	e426                	sd	s1,8(sp)
    80003d9e:	1000                	addi	s0,sp,32
    80003da0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003da2:	0001c517          	auipc	a0,0x1c
    80003da6:	58650513          	addi	a0,a0,1414 # 80020328 <itable>
    80003daa:	ffffd097          	auipc	ra,0xffffd
    80003dae:	e40080e7          	jalr	-448(ra) # 80000bea <acquire>
  ip->ref++;
    80003db2:	449c                	lw	a5,8(s1)
    80003db4:	2785                	addiw	a5,a5,1
    80003db6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003db8:	0001c517          	auipc	a0,0x1c
    80003dbc:	57050513          	addi	a0,a0,1392 # 80020328 <itable>
    80003dc0:	ffffd097          	auipc	ra,0xffffd
    80003dc4:	ede080e7          	jalr	-290(ra) # 80000c9e <release>
}
    80003dc8:	8526                	mv	a0,s1
    80003dca:	60e2                	ld	ra,24(sp)
    80003dcc:	6442                	ld	s0,16(sp)
    80003dce:	64a2                	ld	s1,8(sp)
    80003dd0:	6105                	addi	sp,sp,32
    80003dd2:	8082                	ret

0000000080003dd4 <ilock>:
{
    80003dd4:	1101                	addi	sp,sp,-32
    80003dd6:	ec06                	sd	ra,24(sp)
    80003dd8:	e822                	sd	s0,16(sp)
    80003dda:	e426                	sd	s1,8(sp)
    80003ddc:	e04a                	sd	s2,0(sp)
    80003dde:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003de0:	c115                	beqz	a0,80003e04 <ilock+0x30>
    80003de2:	84aa                	mv	s1,a0
    80003de4:	451c                	lw	a5,8(a0)
    80003de6:	00f05f63          	blez	a5,80003e04 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003dea:	0541                	addi	a0,a0,16
    80003dec:	00001097          	auipc	ra,0x1
    80003df0:	ca2080e7          	jalr	-862(ra) # 80004a8e <acquiresleep>
  if(ip->valid == 0){
    80003df4:	40bc                	lw	a5,64(s1)
    80003df6:	cf99                	beqz	a5,80003e14 <ilock+0x40>
}
    80003df8:	60e2                	ld	ra,24(sp)
    80003dfa:	6442                	ld	s0,16(sp)
    80003dfc:	64a2                	ld	s1,8(sp)
    80003dfe:	6902                	ld	s2,0(sp)
    80003e00:	6105                	addi	sp,sp,32
    80003e02:	8082                	ret
    panic("ilock");
    80003e04:	00005517          	auipc	a0,0x5
    80003e08:	92450513          	addi	a0,a0,-1756 # 80008728 <syscalls+0x1b0>
    80003e0c:	ffffc097          	auipc	ra,0xffffc
    80003e10:	738080e7          	jalr	1848(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e14:	40dc                	lw	a5,4(s1)
    80003e16:	0047d79b          	srliw	a5,a5,0x4
    80003e1a:	0001c597          	auipc	a1,0x1c
    80003e1e:	5065a583          	lw	a1,1286(a1) # 80020320 <sb+0x18>
    80003e22:	9dbd                	addw	a1,a1,a5
    80003e24:	4088                	lw	a0,0(s1)
    80003e26:	fffff097          	auipc	ra,0xfffff
    80003e2a:	794080e7          	jalr	1940(ra) # 800035ba <bread>
    80003e2e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e30:	05850593          	addi	a1,a0,88
    80003e34:	40dc                	lw	a5,4(s1)
    80003e36:	8bbd                	andi	a5,a5,15
    80003e38:	079a                	slli	a5,a5,0x6
    80003e3a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003e3c:	00059783          	lh	a5,0(a1)
    80003e40:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003e44:	00259783          	lh	a5,2(a1)
    80003e48:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003e4c:	00459783          	lh	a5,4(a1)
    80003e50:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003e54:	00659783          	lh	a5,6(a1)
    80003e58:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003e5c:	459c                	lw	a5,8(a1)
    80003e5e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003e60:	03400613          	li	a2,52
    80003e64:	05b1                	addi	a1,a1,12
    80003e66:	05048513          	addi	a0,s1,80
    80003e6a:	ffffd097          	auipc	ra,0xffffd
    80003e6e:	edc080e7          	jalr	-292(ra) # 80000d46 <memmove>
    brelse(bp);
    80003e72:	854a                	mv	a0,s2
    80003e74:	00000097          	auipc	ra,0x0
    80003e78:	876080e7          	jalr	-1930(ra) # 800036ea <brelse>
    ip->valid = 1;
    80003e7c:	4785                	li	a5,1
    80003e7e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003e80:	04449783          	lh	a5,68(s1)
    80003e84:	fbb5                	bnez	a5,80003df8 <ilock+0x24>
      panic("ilock: no type");
    80003e86:	00005517          	auipc	a0,0x5
    80003e8a:	8aa50513          	addi	a0,a0,-1878 # 80008730 <syscalls+0x1b8>
    80003e8e:	ffffc097          	auipc	ra,0xffffc
    80003e92:	6b6080e7          	jalr	1718(ra) # 80000544 <panic>

0000000080003e96 <iunlock>:
{
    80003e96:	1101                	addi	sp,sp,-32
    80003e98:	ec06                	sd	ra,24(sp)
    80003e9a:	e822                	sd	s0,16(sp)
    80003e9c:	e426                	sd	s1,8(sp)
    80003e9e:	e04a                	sd	s2,0(sp)
    80003ea0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003ea2:	c905                	beqz	a0,80003ed2 <iunlock+0x3c>
    80003ea4:	84aa                	mv	s1,a0
    80003ea6:	01050913          	addi	s2,a0,16
    80003eaa:	854a                	mv	a0,s2
    80003eac:	00001097          	auipc	ra,0x1
    80003eb0:	c7c080e7          	jalr	-900(ra) # 80004b28 <holdingsleep>
    80003eb4:	cd19                	beqz	a0,80003ed2 <iunlock+0x3c>
    80003eb6:	449c                	lw	a5,8(s1)
    80003eb8:	00f05d63          	blez	a5,80003ed2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ebc:	854a                	mv	a0,s2
    80003ebe:	00001097          	auipc	ra,0x1
    80003ec2:	c26080e7          	jalr	-986(ra) # 80004ae4 <releasesleep>
}
    80003ec6:	60e2                	ld	ra,24(sp)
    80003ec8:	6442                	ld	s0,16(sp)
    80003eca:	64a2                	ld	s1,8(sp)
    80003ecc:	6902                	ld	s2,0(sp)
    80003ece:	6105                	addi	sp,sp,32
    80003ed0:	8082                	ret
    panic("iunlock");
    80003ed2:	00005517          	auipc	a0,0x5
    80003ed6:	86e50513          	addi	a0,a0,-1938 # 80008740 <syscalls+0x1c8>
    80003eda:	ffffc097          	auipc	ra,0xffffc
    80003ede:	66a080e7          	jalr	1642(ra) # 80000544 <panic>

0000000080003ee2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ee2:	7179                	addi	sp,sp,-48
    80003ee4:	f406                	sd	ra,40(sp)
    80003ee6:	f022                	sd	s0,32(sp)
    80003ee8:	ec26                	sd	s1,24(sp)
    80003eea:	e84a                	sd	s2,16(sp)
    80003eec:	e44e                	sd	s3,8(sp)
    80003eee:	e052                	sd	s4,0(sp)
    80003ef0:	1800                	addi	s0,sp,48
    80003ef2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003ef4:	05050493          	addi	s1,a0,80
    80003ef8:	08050913          	addi	s2,a0,128
    80003efc:	a021                	j	80003f04 <itrunc+0x22>
    80003efe:	0491                	addi	s1,s1,4
    80003f00:	01248d63          	beq	s1,s2,80003f1a <itrunc+0x38>
    if(ip->addrs[i]){
    80003f04:	408c                	lw	a1,0(s1)
    80003f06:	dde5                	beqz	a1,80003efe <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003f08:	0009a503          	lw	a0,0(s3)
    80003f0c:	00000097          	auipc	ra,0x0
    80003f10:	8f4080e7          	jalr	-1804(ra) # 80003800 <bfree>
      ip->addrs[i] = 0;
    80003f14:	0004a023          	sw	zero,0(s1)
    80003f18:	b7dd                	j	80003efe <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003f1a:	0809a583          	lw	a1,128(s3)
    80003f1e:	e185                	bnez	a1,80003f3e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003f20:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003f24:	854e                	mv	a0,s3
    80003f26:	00000097          	auipc	ra,0x0
    80003f2a:	de4080e7          	jalr	-540(ra) # 80003d0a <iupdate>
}
    80003f2e:	70a2                	ld	ra,40(sp)
    80003f30:	7402                	ld	s0,32(sp)
    80003f32:	64e2                	ld	s1,24(sp)
    80003f34:	6942                	ld	s2,16(sp)
    80003f36:	69a2                	ld	s3,8(sp)
    80003f38:	6a02                	ld	s4,0(sp)
    80003f3a:	6145                	addi	sp,sp,48
    80003f3c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003f3e:	0009a503          	lw	a0,0(s3)
    80003f42:	fffff097          	auipc	ra,0xfffff
    80003f46:	678080e7          	jalr	1656(ra) # 800035ba <bread>
    80003f4a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003f4c:	05850493          	addi	s1,a0,88
    80003f50:	45850913          	addi	s2,a0,1112
    80003f54:	a811                	j	80003f68 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003f56:	0009a503          	lw	a0,0(s3)
    80003f5a:	00000097          	auipc	ra,0x0
    80003f5e:	8a6080e7          	jalr	-1882(ra) # 80003800 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003f62:	0491                	addi	s1,s1,4
    80003f64:	01248563          	beq	s1,s2,80003f6e <itrunc+0x8c>
      if(a[j])
    80003f68:	408c                	lw	a1,0(s1)
    80003f6a:	dde5                	beqz	a1,80003f62 <itrunc+0x80>
    80003f6c:	b7ed                	j	80003f56 <itrunc+0x74>
    brelse(bp);
    80003f6e:	8552                	mv	a0,s4
    80003f70:	fffff097          	auipc	ra,0xfffff
    80003f74:	77a080e7          	jalr	1914(ra) # 800036ea <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003f78:	0809a583          	lw	a1,128(s3)
    80003f7c:	0009a503          	lw	a0,0(s3)
    80003f80:	00000097          	auipc	ra,0x0
    80003f84:	880080e7          	jalr	-1920(ra) # 80003800 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003f88:	0809a023          	sw	zero,128(s3)
    80003f8c:	bf51                	j	80003f20 <itrunc+0x3e>

0000000080003f8e <iput>:
{
    80003f8e:	1101                	addi	sp,sp,-32
    80003f90:	ec06                	sd	ra,24(sp)
    80003f92:	e822                	sd	s0,16(sp)
    80003f94:	e426                	sd	s1,8(sp)
    80003f96:	e04a                	sd	s2,0(sp)
    80003f98:	1000                	addi	s0,sp,32
    80003f9a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003f9c:	0001c517          	auipc	a0,0x1c
    80003fa0:	38c50513          	addi	a0,a0,908 # 80020328 <itable>
    80003fa4:	ffffd097          	auipc	ra,0xffffd
    80003fa8:	c46080e7          	jalr	-954(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003fac:	4498                	lw	a4,8(s1)
    80003fae:	4785                	li	a5,1
    80003fb0:	02f70363          	beq	a4,a5,80003fd6 <iput+0x48>
  ip->ref--;
    80003fb4:	449c                	lw	a5,8(s1)
    80003fb6:	37fd                	addiw	a5,a5,-1
    80003fb8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003fba:	0001c517          	auipc	a0,0x1c
    80003fbe:	36e50513          	addi	a0,a0,878 # 80020328 <itable>
    80003fc2:	ffffd097          	auipc	ra,0xffffd
    80003fc6:	cdc080e7          	jalr	-804(ra) # 80000c9e <release>
}
    80003fca:	60e2                	ld	ra,24(sp)
    80003fcc:	6442                	ld	s0,16(sp)
    80003fce:	64a2                	ld	s1,8(sp)
    80003fd0:	6902                	ld	s2,0(sp)
    80003fd2:	6105                	addi	sp,sp,32
    80003fd4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003fd6:	40bc                	lw	a5,64(s1)
    80003fd8:	dff1                	beqz	a5,80003fb4 <iput+0x26>
    80003fda:	04a49783          	lh	a5,74(s1)
    80003fde:	fbf9                	bnez	a5,80003fb4 <iput+0x26>
    acquiresleep(&ip->lock);
    80003fe0:	01048913          	addi	s2,s1,16
    80003fe4:	854a                	mv	a0,s2
    80003fe6:	00001097          	auipc	ra,0x1
    80003fea:	aa8080e7          	jalr	-1368(ra) # 80004a8e <acquiresleep>
    release(&itable.lock);
    80003fee:	0001c517          	auipc	a0,0x1c
    80003ff2:	33a50513          	addi	a0,a0,826 # 80020328 <itable>
    80003ff6:	ffffd097          	auipc	ra,0xffffd
    80003ffa:	ca8080e7          	jalr	-856(ra) # 80000c9e <release>
    itrunc(ip);
    80003ffe:	8526                	mv	a0,s1
    80004000:	00000097          	auipc	ra,0x0
    80004004:	ee2080e7          	jalr	-286(ra) # 80003ee2 <itrunc>
    ip->type = 0;
    80004008:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000400c:	8526                	mv	a0,s1
    8000400e:	00000097          	auipc	ra,0x0
    80004012:	cfc080e7          	jalr	-772(ra) # 80003d0a <iupdate>
    ip->valid = 0;
    80004016:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000401a:	854a                	mv	a0,s2
    8000401c:	00001097          	auipc	ra,0x1
    80004020:	ac8080e7          	jalr	-1336(ra) # 80004ae4 <releasesleep>
    acquire(&itable.lock);
    80004024:	0001c517          	auipc	a0,0x1c
    80004028:	30450513          	addi	a0,a0,772 # 80020328 <itable>
    8000402c:	ffffd097          	auipc	ra,0xffffd
    80004030:	bbe080e7          	jalr	-1090(ra) # 80000bea <acquire>
    80004034:	b741                	j	80003fb4 <iput+0x26>

0000000080004036 <iunlockput>:
{
    80004036:	1101                	addi	sp,sp,-32
    80004038:	ec06                	sd	ra,24(sp)
    8000403a:	e822                	sd	s0,16(sp)
    8000403c:	e426                	sd	s1,8(sp)
    8000403e:	1000                	addi	s0,sp,32
    80004040:	84aa                	mv	s1,a0
  iunlock(ip);
    80004042:	00000097          	auipc	ra,0x0
    80004046:	e54080e7          	jalr	-428(ra) # 80003e96 <iunlock>
  iput(ip);
    8000404a:	8526                	mv	a0,s1
    8000404c:	00000097          	auipc	ra,0x0
    80004050:	f42080e7          	jalr	-190(ra) # 80003f8e <iput>
}
    80004054:	60e2                	ld	ra,24(sp)
    80004056:	6442                	ld	s0,16(sp)
    80004058:	64a2                	ld	s1,8(sp)
    8000405a:	6105                	addi	sp,sp,32
    8000405c:	8082                	ret

000000008000405e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000405e:	1141                	addi	sp,sp,-16
    80004060:	e422                	sd	s0,8(sp)
    80004062:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004064:	411c                	lw	a5,0(a0)
    80004066:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004068:	415c                	lw	a5,4(a0)
    8000406a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000406c:	04451783          	lh	a5,68(a0)
    80004070:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004074:	04a51783          	lh	a5,74(a0)
    80004078:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000407c:	04c56783          	lwu	a5,76(a0)
    80004080:	e99c                	sd	a5,16(a1)
}
    80004082:	6422                	ld	s0,8(sp)
    80004084:	0141                	addi	sp,sp,16
    80004086:	8082                	ret

0000000080004088 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004088:	457c                	lw	a5,76(a0)
    8000408a:	0ed7e963          	bltu	a5,a3,8000417c <readi+0xf4>
{
    8000408e:	7159                	addi	sp,sp,-112
    80004090:	f486                	sd	ra,104(sp)
    80004092:	f0a2                	sd	s0,96(sp)
    80004094:	eca6                	sd	s1,88(sp)
    80004096:	e8ca                	sd	s2,80(sp)
    80004098:	e4ce                	sd	s3,72(sp)
    8000409a:	e0d2                	sd	s4,64(sp)
    8000409c:	fc56                	sd	s5,56(sp)
    8000409e:	f85a                	sd	s6,48(sp)
    800040a0:	f45e                	sd	s7,40(sp)
    800040a2:	f062                	sd	s8,32(sp)
    800040a4:	ec66                	sd	s9,24(sp)
    800040a6:	e86a                	sd	s10,16(sp)
    800040a8:	e46e                	sd	s11,8(sp)
    800040aa:	1880                	addi	s0,sp,112
    800040ac:	8b2a                	mv	s6,a0
    800040ae:	8bae                	mv	s7,a1
    800040b0:	8a32                	mv	s4,a2
    800040b2:	84b6                	mv	s1,a3
    800040b4:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    800040b6:	9f35                	addw	a4,a4,a3
    return 0;
    800040b8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800040ba:	0ad76063          	bltu	a4,a3,8000415a <readi+0xd2>
  if(off + n > ip->size)
    800040be:	00e7f463          	bgeu	a5,a4,800040c6 <readi+0x3e>
    n = ip->size - off;
    800040c2:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040c6:	0a0a8963          	beqz	s5,80004178 <readi+0xf0>
    800040ca:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800040cc:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800040d0:	5c7d                	li	s8,-1
    800040d2:	a82d                	j	8000410c <readi+0x84>
    800040d4:	020d1d93          	slli	s11,s10,0x20
    800040d8:	020ddd93          	srli	s11,s11,0x20
    800040dc:	05890613          	addi	a2,s2,88
    800040e0:	86ee                	mv	a3,s11
    800040e2:	963a                	add	a2,a2,a4
    800040e4:	85d2                	mv	a1,s4
    800040e6:	855e                	mv	a0,s7
    800040e8:	ffffe097          	auipc	ra,0xffffe
    800040ec:	7fe080e7          	jalr	2046(ra) # 800028e6 <either_copyout>
    800040f0:	05850d63          	beq	a0,s8,8000414a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800040f4:	854a                	mv	a0,s2
    800040f6:	fffff097          	auipc	ra,0xfffff
    800040fa:	5f4080e7          	jalr	1524(ra) # 800036ea <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040fe:	013d09bb          	addw	s3,s10,s3
    80004102:	009d04bb          	addw	s1,s10,s1
    80004106:	9a6e                	add	s4,s4,s11
    80004108:	0559f763          	bgeu	s3,s5,80004156 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    8000410c:	00a4d59b          	srliw	a1,s1,0xa
    80004110:	855a                	mv	a0,s6
    80004112:	00000097          	auipc	ra,0x0
    80004116:	8a2080e7          	jalr	-1886(ra) # 800039b4 <bmap>
    8000411a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000411e:	cd85                	beqz	a1,80004156 <readi+0xce>
    bp = bread(ip->dev, addr);
    80004120:	000b2503          	lw	a0,0(s6)
    80004124:	fffff097          	auipc	ra,0xfffff
    80004128:	496080e7          	jalr	1174(ra) # 800035ba <bread>
    8000412c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000412e:	3ff4f713          	andi	a4,s1,1023
    80004132:	40ec87bb          	subw	a5,s9,a4
    80004136:	413a86bb          	subw	a3,s5,s3
    8000413a:	8d3e                	mv	s10,a5
    8000413c:	2781                	sext.w	a5,a5
    8000413e:	0006861b          	sext.w	a2,a3
    80004142:	f8f679e3          	bgeu	a2,a5,800040d4 <readi+0x4c>
    80004146:	8d36                	mv	s10,a3
    80004148:	b771                	j	800040d4 <readi+0x4c>
      brelse(bp);
    8000414a:	854a                	mv	a0,s2
    8000414c:	fffff097          	auipc	ra,0xfffff
    80004150:	59e080e7          	jalr	1438(ra) # 800036ea <brelse>
      tot = -1;
    80004154:	59fd                	li	s3,-1
  }
  return tot;
    80004156:	0009851b          	sext.w	a0,s3
}
    8000415a:	70a6                	ld	ra,104(sp)
    8000415c:	7406                	ld	s0,96(sp)
    8000415e:	64e6                	ld	s1,88(sp)
    80004160:	6946                	ld	s2,80(sp)
    80004162:	69a6                	ld	s3,72(sp)
    80004164:	6a06                	ld	s4,64(sp)
    80004166:	7ae2                	ld	s5,56(sp)
    80004168:	7b42                	ld	s6,48(sp)
    8000416a:	7ba2                	ld	s7,40(sp)
    8000416c:	7c02                	ld	s8,32(sp)
    8000416e:	6ce2                	ld	s9,24(sp)
    80004170:	6d42                	ld	s10,16(sp)
    80004172:	6da2                	ld	s11,8(sp)
    80004174:	6165                	addi	sp,sp,112
    80004176:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004178:	89d6                	mv	s3,s5
    8000417a:	bff1                	j	80004156 <readi+0xce>
    return 0;
    8000417c:	4501                	li	a0,0
}
    8000417e:	8082                	ret

0000000080004180 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004180:	457c                	lw	a5,76(a0)
    80004182:	10d7e863          	bltu	a5,a3,80004292 <writei+0x112>
{
    80004186:	7159                	addi	sp,sp,-112
    80004188:	f486                	sd	ra,104(sp)
    8000418a:	f0a2                	sd	s0,96(sp)
    8000418c:	eca6                	sd	s1,88(sp)
    8000418e:	e8ca                	sd	s2,80(sp)
    80004190:	e4ce                	sd	s3,72(sp)
    80004192:	e0d2                	sd	s4,64(sp)
    80004194:	fc56                	sd	s5,56(sp)
    80004196:	f85a                	sd	s6,48(sp)
    80004198:	f45e                	sd	s7,40(sp)
    8000419a:	f062                	sd	s8,32(sp)
    8000419c:	ec66                	sd	s9,24(sp)
    8000419e:	e86a                	sd	s10,16(sp)
    800041a0:	e46e                	sd	s11,8(sp)
    800041a2:	1880                	addi	s0,sp,112
    800041a4:	8aaa                	mv	s5,a0
    800041a6:	8bae                	mv	s7,a1
    800041a8:	8a32                	mv	s4,a2
    800041aa:	8936                	mv	s2,a3
    800041ac:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800041ae:	00e687bb          	addw	a5,a3,a4
    800041b2:	0ed7e263          	bltu	a5,a3,80004296 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800041b6:	00043737          	lui	a4,0x43
    800041ba:	0ef76063          	bltu	a4,a5,8000429a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041be:	0c0b0863          	beqz	s6,8000428e <writei+0x10e>
    800041c2:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800041c4:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800041c8:	5c7d                	li	s8,-1
    800041ca:	a091                	j	8000420e <writei+0x8e>
    800041cc:	020d1d93          	slli	s11,s10,0x20
    800041d0:	020ddd93          	srli	s11,s11,0x20
    800041d4:	05848513          	addi	a0,s1,88
    800041d8:	86ee                	mv	a3,s11
    800041da:	8652                	mv	a2,s4
    800041dc:	85de                	mv	a1,s7
    800041de:	953a                	add	a0,a0,a4
    800041e0:	ffffe097          	auipc	ra,0xffffe
    800041e4:	75c080e7          	jalr	1884(ra) # 8000293c <either_copyin>
    800041e8:	07850263          	beq	a0,s8,8000424c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800041ec:	8526                	mv	a0,s1
    800041ee:	00000097          	auipc	ra,0x0
    800041f2:	780080e7          	jalr	1920(ra) # 8000496e <log_write>
    brelse(bp);
    800041f6:	8526                	mv	a0,s1
    800041f8:	fffff097          	auipc	ra,0xfffff
    800041fc:	4f2080e7          	jalr	1266(ra) # 800036ea <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004200:	013d09bb          	addw	s3,s10,s3
    80004204:	012d093b          	addw	s2,s10,s2
    80004208:	9a6e                	add	s4,s4,s11
    8000420a:	0569f663          	bgeu	s3,s6,80004256 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    8000420e:	00a9559b          	srliw	a1,s2,0xa
    80004212:	8556                	mv	a0,s5
    80004214:	fffff097          	auipc	ra,0xfffff
    80004218:	7a0080e7          	jalr	1952(ra) # 800039b4 <bmap>
    8000421c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004220:	c99d                	beqz	a1,80004256 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004222:	000aa503          	lw	a0,0(s5)
    80004226:	fffff097          	auipc	ra,0xfffff
    8000422a:	394080e7          	jalr	916(ra) # 800035ba <bread>
    8000422e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004230:	3ff97713          	andi	a4,s2,1023
    80004234:	40ec87bb          	subw	a5,s9,a4
    80004238:	413b06bb          	subw	a3,s6,s3
    8000423c:	8d3e                	mv	s10,a5
    8000423e:	2781                	sext.w	a5,a5
    80004240:	0006861b          	sext.w	a2,a3
    80004244:	f8f674e3          	bgeu	a2,a5,800041cc <writei+0x4c>
    80004248:	8d36                	mv	s10,a3
    8000424a:	b749                	j	800041cc <writei+0x4c>
      brelse(bp);
    8000424c:	8526                	mv	a0,s1
    8000424e:	fffff097          	auipc	ra,0xfffff
    80004252:	49c080e7          	jalr	1180(ra) # 800036ea <brelse>
  }

  if(off > ip->size)
    80004256:	04caa783          	lw	a5,76(s5)
    8000425a:	0127f463          	bgeu	a5,s2,80004262 <writei+0xe2>
    ip->size = off;
    8000425e:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004262:	8556                	mv	a0,s5
    80004264:	00000097          	auipc	ra,0x0
    80004268:	aa6080e7          	jalr	-1370(ra) # 80003d0a <iupdate>

  return tot;
    8000426c:	0009851b          	sext.w	a0,s3
}
    80004270:	70a6                	ld	ra,104(sp)
    80004272:	7406                	ld	s0,96(sp)
    80004274:	64e6                	ld	s1,88(sp)
    80004276:	6946                	ld	s2,80(sp)
    80004278:	69a6                	ld	s3,72(sp)
    8000427a:	6a06                	ld	s4,64(sp)
    8000427c:	7ae2                	ld	s5,56(sp)
    8000427e:	7b42                	ld	s6,48(sp)
    80004280:	7ba2                	ld	s7,40(sp)
    80004282:	7c02                	ld	s8,32(sp)
    80004284:	6ce2                	ld	s9,24(sp)
    80004286:	6d42                	ld	s10,16(sp)
    80004288:	6da2                	ld	s11,8(sp)
    8000428a:	6165                	addi	sp,sp,112
    8000428c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000428e:	89da                	mv	s3,s6
    80004290:	bfc9                	j	80004262 <writei+0xe2>
    return -1;
    80004292:	557d                	li	a0,-1
}
    80004294:	8082                	ret
    return -1;
    80004296:	557d                	li	a0,-1
    80004298:	bfe1                	j	80004270 <writei+0xf0>
    return -1;
    8000429a:	557d                	li	a0,-1
    8000429c:	bfd1                	j	80004270 <writei+0xf0>

000000008000429e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000429e:	1141                	addi	sp,sp,-16
    800042a0:	e406                	sd	ra,8(sp)
    800042a2:	e022                	sd	s0,0(sp)
    800042a4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800042a6:	4639                	li	a2,14
    800042a8:	ffffd097          	auipc	ra,0xffffd
    800042ac:	b16080e7          	jalr	-1258(ra) # 80000dbe <strncmp>
}
    800042b0:	60a2                	ld	ra,8(sp)
    800042b2:	6402                	ld	s0,0(sp)
    800042b4:	0141                	addi	sp,sp,16
    800042b6:	8082                	ret

00000000800042b8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800042b8:	7139                	addi	sp,sp,-64
    800042ba:	fc06                	sd	ra,56(sp)
    800042bc:	f822                	sd	s0,48(sp)
    800042be:	f426                	sd	s1,40(sp)
    800042c0:	f04a                	sd	s2,32(sp)
    800042c2:	ec4e                	sd	s3,24(sp)
    800042c4:	e852                	sd	s4,16(sp)
    800042c6:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800042c8:	04451703          	lh	a4,68(a0)
    800042cc:	4785                	li	a5,1
    800042ce:	00f71a63          	bne	a4,a5,800042e2 <dirlookup+0x2a>
    800042d2:	892a                	mv	s2,a0
    800042d4:	89ae                	mv	s3,a1
    800042d6:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800042d8:	457c                	lw	a5,76(a0)
    800042da:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800042dc:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042de:	e79d                	bnez	a5,8000430c <dirlookup+0x54>
    800042e0:	a8a5                	j	80004358 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800042e2:	00004517          	auipc	a0,0x4
    800042e6:	46650513          	addi	a0,a0,1126 # 80008748 <syscalls+0x1d0>
    800042ea:	ffffc097          	auipc	ra,0xffffc
    800042ee:	25a080e7          	jalr	602(ra) # 80000544 <panic>
      panic("dirlookup read");
    800042f2:	00004517          	auipc	a0,0x4
    800042f6:	46e50513          	addi	a0,a0,1134 # 80008760 <syscalls+0x1e8>
    800042fa:	ffffc097          	auipc	ra,0xffffc
    800042fe:	24a080e7          	jalr	586(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004302:	24c1                	addiw	s1,s1,16
    80004304:	04c92783          	lw	a5,76(s2)
    80004308:	04f4f763          	bgeu	s1,a5,80004356 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000430c:	4741                	li	a4,16
    8000430e:	86a6                	mv	a3,s1
    80004310:	fc040613          	addi	a2,s0,-64
    80004314:	4581                	li	a1,0
    80004316:	854a                	mv	a0,s2
    80004318:	00000097          	auipc	ra,0x0
    8000431c:	d70080e7          	jalr	-656(ra) # 80004088 <readi>
    80004320:	47c1                	li	a5,16
    80004322:	fcf518e3          	bne	a0,a5,800042f2 <dirlookup+0x3a>
    if(de.inum == 0)
    80004326:	fc045783          	lhu	a5,-64(s0)
    8000432a:	dfe1                	beqz	a5,80004302 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000432c:	fc240593          	addi	a1,s0,-62
    80004330:	854e                	mv	a0,s3
    80004332:	00000097          	auipc	ra,0x0
    80004336:	f6c080e7          	jalr	-148(ra) # 8000429e <namecmp>
    8000433a:	f561                	bnez	a0,80004302 <dirlookup+0x4a>
      if(poff)
    8000433c:	000a0463          	beqz	s4,80004344 <dirlookup+0x8c>
        *poff = off;
    80004340:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004344:	fc045583          	lhu	a1,-64(s0)
    80004348:	00092503          	lw	a0,0(s2)
    8000434c:	fffff097          	auipc	ra,0xfffff
    80004350:	750080e7          	jalr	1872(ra) # 80003a9c <iget>
    80004354:	a011                	j	80004358 <dirlookup+0xa0>
  return 0;
    80004356:	4501                	li	a0,0
}
    80004358:	70e2                	ld	ra,56(sp)
    8000435a:	7442                	ld	s0,48(sp)
    8000435c:	74a2                	ld	s1,40(sp)
    8000435e:	7902                	ld	s2,32(sp)
    80004360:	69e2                	ld	s3,24(sp)
    80004362:	6a42                	ld	s4,16(sp)
    80004364:	6121                	addi	sp,sp,64
    80004366:	8082                	ret

0000000080004368 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004368:	711d                	addi	sp,sp,-96
    8000436a:	ec86                	sd	ra,88(sp)
    8000436c:	e8a2                	sd	s0,80(sp)
    8000436e:	e4a6                	sd	s1,72(sp)
    80004370:	e0ca                	sd	s2,64(sp)
    80004372:	fc4e                	sd	s3,56(sp)
    80004374:	f852                	sd	s4,48(sp)
    80004376:	f456                	sd	s5,40(sp)
    80004378:	f05a                	sd	s6,32(sp)
    8000437a:	ec5e                	sd	s7,24(sp)
    8000437c:	e862                	sd	s8,16(sp)
    8000437e:	e466                	sd	s9,8(sp)
    80004380:	1080                	addi	s0,sp,96
    80004382:	84aa                	mv	s1,a0
    80004384:	8b2e                	mv	s6,a1
    80004386:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004388:	00054703          	lbu	a4,0(a0)
    8000438c:	02f00793          	li	a5,47
    80004390:	02f70363          	beq	a4,a5,800043b6 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004394:	ffffd097          	auipc	ra,0xffffd
    80004398:	632080e7          	jalr	1586(ra) # 800019c6 <myproc>
    8000439c:	15053503          	ld	a0,336(a0)
    800043a0:	00000097          	auipc	ra,0x0
    800043a4:	9f6080e7          	jalr	-1546(ra) # 80003d96 <idup>
    800043a8:	89aa                	mv	s3,a0
  while(*path == '/')
    800043aa:	02f00913          	li	s2,47
  len = path - s;
    800043ae:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800043b0:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800043b2:	4c05                	li	s8,1
    800043b4:	a865                	j	8000446c <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800043b6:	4585                	li	a1,1
    800043b8:	4505                	li	a0,1
    800043ba:	fffff097          	auipc	ra,0xfffff
    800043be:	6e2080e7          	jalr	1762(ra) # 80003a9c <iget>
    800043c2:	89aa                	mv	s3,a0
    800043c4:	b7dd                	j	800043aa <namex+0x42>
      iunlockput(ip);
    800043c6:	854e                	mv	a0,s3
    800043c8:	00000097          	auipc	ra,0x0
    800043cc:	c6e080e7          	jalr	-914(ra) # 80004036 <iunlockput>
      return 0;
    800043d0:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800043d2:	854e                	mv	a0,s3
    800043d4:	60e6                	ld	ra,88(sp)
    800043d6:	6446                	ld	s0,80(sp)
    800043d8:	64a6                	ld	s1,72(sp)
    800043da:	6906                	ld	s2,64(sp)
    800043dc:	79e2                	ld	s3,56(sp)
    800043de:	7a42                	ld	s4,48(sp)
    800043e0:	7aa2                	ld	s5,40(sp)
    800043e2:	7b02                	ld	s6,32(sp)
    800043e4:	6be2                	ld	s7,24(sp)
    800043e6:	6c42                	ld	s8,16(sp)
    800043e8:	6ca2                	ld	s9,8(sp)
    800043ea:	6125                	addi	sp,sp,96
    800043ec:	8082                	ret
      iunlock(ip);
    800043ee:	854e                	mv	a0,s3
    800043f0:	00000097          	auipc	ra,0x0
    800043f4:	aa6080e7          	jalr	-1370(ra) # 80003e96 <iunlock>
      return ip;
    800043f8:	bfe9                	j	800043d2 <namex+0x6a>
      iunlockput(ip);
    800043fa:	854e                	mv	a0,s3
    800043fc:	00000097          	auipc	ra,0x0
    80004400:	c3a080e7          	jalr	-966(ra) # 80004036 <iunlockput>
      return 0;
    80004404:	89d2                	mv	s3,s4
    80004406:	b7f1                	j	800043d2 <namex+0x6a>
  len = path - s;
    80004408:	40b48633          	sub	a2,s1,a1
    8000440c:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004410:	094cd463          	bge	s9,s4,80004498 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004414:	4639                	li	a2,14
    80004416:	8556                	mv	a0,s5
    80004418:	ffffd097          	auipc	ra,0xffffd
    8000441c:	92e080e7          	jalr	-1746(ra) # 80000d46 <memmove>
  while(*path == '/')
    80004420:	0004c783          	lbu	a5,0(s1)
    80004424:	01279763          	bne	a5,s2,80004432 <namex+0xca>
    path++;
    80004428:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000442a:	0004c783          	lbu	a5,0(s1)
    8000442e:	ff278de3          	beq	a5,s2,80004428 <namex+0xc0>
    ilock(ip);
    80004432:	854e                	mv	a0,s3
    80004434:	00000097          	auipc	ra,0x0
    80004438:	9a0080e7          	jalr	-1632(ra) # 80003dd4 <ilock>
    if(ip->type != T_DIR){
    8000443c:	04499783          	lh	a5,68(s3)
    80004440:	f98793e3          	bne	a5,s8,800043c6 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004444:	000b0563          	beqz	s6,8000444e <namex+0xe6>
    80004448:	0004c783          	lbu	a5,0(s1)
    8000444c:	d3cd                	beqz	a5,800043ee <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000444e:	865e                	mv	a2,s7
    80004450:	85d6                	mv	a1,s5
    80004452:	854e                	mv	a0,s3
    80004454:	00000097          	auipc	ra,0x0
    80004458:	e64080e7          	jalr	-412(ra) # 800042b8 <dirlookup>
    8000445c:	8a2a                	mv	s4,a0
    8000445e:	dd51                	beqz	a0,800043fa <namex+0x92>
    iunlockput(ip);
    80004460:	854e                	mv	a0,s3
    80004462:	00000097          	auipc	ra,0x0
    80004466:	bd4080e7          	jalr	-1068(ra) # 80004036 <iunlockput>
    ip = next;
    8000446a:	89d2                	mv	s3,s4
  while(*path == '/')
    8000446c:	0004c783          	lbu	a5,0(s1)
    80004470:	05279763          	bne	a5,s2,800044be <namex+0x156>
    path++;
    80004474:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004476:	0004c783          	lbu	a5,0(s1)
    8000447a:	ff278de3          	beq	a5,s2,80004474 <namex+0x10c>
  if(*path == 0)
    8000447e:	c79d                	beqz	a5,800044ac <namex+0x144>
    path++;
    80004480:	85a6                	mv	a1,s1
  len = path - s;
    80004482:	8a5e                	mv	s4,s7
    80004484:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004486:	01278963          	beq	a5,s2,80004498 <namex+0x130>
    8000448a:	dfbd                	beqz	a5,80004408 <namex+0xa0>
    path++;
    8000448c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000448e:	0004c783          	lbu	a5,0(s1)
    80004492:	ff279ce3          	bne	a5,s2,8000448a <namex+0x122>
    80004496:	bf8d                	j	80004408 <namex+0xa0>
    memmove(name, s, len);
    80004498:	2601                	sext.w	a2,a2
    8000449a:	8556                	mv	a0,s5
    8000449c:	ffffd097          	auipc	ra,0xffffd
    800044a0:	8aa080e7          	jalr	-1878(ra) # 80000d46 <memmove>
    name[len] = 0;
    800044a4:	9a56                	add	s4,s4,s5
    800044a6:	000a0023          	sb	zero,0(s4)
    800044aa:	bf9d                	j	80004420 <namex+0xb8>
  if(nameiparent){
    800044ac:	f20b03e3          	beqz	s6,800043d2 <namex+0x6a>
    iput(ip);
    800044b0:	854e                	mv	a0,s3
    800044b2:	00000097          	auipc	ra,0x0
    800044b6:	adc080e7          	jalr	-1316(ra) # 80003f8e <iput>
    return 0;
    800044ba:	4981                	li	s3,0
    800044bc:	bf19                	j	800043d2 <namex+0x6a>
  if(*path == 0)
    800044be:	d7fd                	beqz	a5,800044ac <namex+0x144>
  while(*path != '/' && *path != 0)
    800044c0:	0004c783          	lbu	a5,0(s1)
    800044c4:	85a6                	mv	a1,s1
    800044c6:	b7d1                	j	8000448a <namex+0x122>

00000000800044c8 <dirlink>:
{
    800044c8:	7139                	addi	sp,sp,-64
    800044ca:	fc06                	sd	ra,56(sp)
    800044cc:	f822                	sd	s0,48(sp)
    800044ce:	f426                	sd	s1,40(sp)
    800044d0:	f04a                	sd	s2,32(sp)
    800044d2:	ec4e                	sd	s3,24(sp)
    800044d4:	e852                	sd	s4,16(sp)
    800044d6:	0080                	addi	s0,sp,64
    800044d8:	892a                	mv	s2,a0
    800044da:	8a2e                	mv	s4,a1
    800044dc:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800044de:	4601                	li	a2,0
    800044e0:	00000097          	auipc	ra,0x0
    800044e4:	dd8080e7          	jalr	-552(ra) # 800042b8 <dirlookup>
    800044e8:	e93d                	bnez	a0,8000455e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044ea:	04c92483          	lw	s1,76(s2)
    800044ee:	c49d                	beqz	s1,8000451c <dirlink+0x54>
    800044f0:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044f2:	4741                	li	a4,16
    800044f4:	86a6                	mv	a3,s1
    800044f6:	fc040613          	addi	a2,s0,-64
    800044fa:	4581                	li	a1,0
    800044fc:	854a                	mv	a0,s2
    800044fe:	00000097          	auipc	ra,0x0
    80004502:	b8a080e7          	jalr	-1142(ra) # 80004088 <readi>
    80004506:	47c1                	li	a5,16
    80004508:	06f51163          	bne	a0,a5,8000456a <dirlink+0xa2>
    if(de.inum == 0)
    8000450c:	fc045783          	lhu	a5,-64(s0)
    80004510:	c791                	beqz	a5,8000451c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004512:	24c1                	addiw	s1,s1,16
    80004514:	04c92783          	lw	a5,76(s2)
    80004518:	fcf4ede3          	bltu	s1,a5,800044f2 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000451c:	4639                	li	a2,14
    8000451e:	85d2                	mv	a1,s4
    80004520:	fc240513          	addi	a0,s0,-62
    80004524:	ffffd097          	auipc	ra,0xffffd
    80004528:	8d6080e7          	jalr	-1834(ra) # 80000dfa <strncpy>
  de.inum = inum;
    8000452c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004530:	4741                	li	a4,16
    80004532:	86a6                	mv	a3,s1
    80004534:	fc040613          	addi	a2,s0,-64
    80004538:	4581                	li	a1,0
    8000453a:	854a                	mv	a0,s2
    8000453c:	00000097          	auipc	ra,0x0
    80004540:	c44080e7          	jalr	-956(ra) # 80004180 <writei>
    80004544:	1541                	addi	a0,a0,-16
    80004546:	00a03533          	snez	a0,a0
    8000454a:	40a00533          	neg	a0,a0
}
    8000454e:	70e2                	ld	ra,56(sp)
    80004550:	7442                	ld	s0,48(sp)
    80004552:	74a2                	ld	s1,40(sp)
    80004554:	7902                	ld	s2,32(sp)
    80004556:	69e2                	ld	s3,24(sp)
    80004558:	6a42                	ld	s4,16(sp)
    8000455a:	6121                	addi	sp,sp,64
    8000455c:	8082                	ret
    iput(ip);
    8000455e:	00000097          	auipc	ra,0x0
    80004562:	a30080e7          	jalr	-1488(ra) # 80003f8e <iput>
    return -1;
    80004566:	557d                	li	a0,-1
    80004568:	b7dd                	j	8000454e <dirlink+0x86>
      panic("dirlink read");
    8000456a:	00004517          	auipc	a0,0x4
    8000456e:	20650513          	addi	a0,a0,518 # 80008770 <syscalls+0x1f8>
    80004572:	ffffc097          	auipc	ra,0xffffc
    80004576:	fd2080e7          	jalr	-46(ra) # 80000544 <panic>

000000008000457a <namei>:

struct inode*
namei(char *path)
{
    8000457a:	1101                	addi	sp,sp,-32
    8000457c:	ec06                	sd	ra,24(sp)
    8000457e:	e822                	sd	s0,16(sp)
    80004580:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004582:	fe040613          	addi	a2,s0,-32
    80004586:	4581                	li	a1,0
    80004588:	00000097          	auipc	ra,0x0
    8000458c:	de0080e7          	jalr	-544(ra) # 80004368 <namex>
}
    80004590:	60e2                	ld	ra,24(sp)
    80004592:	6442                	ld	s0,16(sp)
    80004594:	6105                	addi	sp,sp,32
    80004596:	8082                	ret

0000000080004598 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004598:	1141                	addi	sp,sp,-16
    8000459a:	e406                	sd	ra,8(sp)
    8000459c:	e022                	sd	s0,0(sp)
    8000459e:	0800                	addi	s0,sp,16
    800045a0:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800045a2:	4585                	li	a1,1
    800045a4:	00000097          	auipc	ra,0x0
    800045a8:	dc4080e7          	jalr	-572(ra) # 80004368 <namex>
}
    800045ac:	60a2                	ld	ra,8(sp)
    800045ae:	6402                	ld	s0,0(sp)
    800045b0:	0141                	addi	sp,sp,16
    800045b2:	8082                	ret

00000000800045b4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800045b4:	1101                	addi	sp,sp,-32
    800045b6:	ec06                	sd	ra,24(sp)
    800045b8:	e822                	sd	s0,16(sp)
    800045ba:	e426                	sd	s1,8(sp)
    800045bc:	e04a                	sd	s2,0(sp)
    800045be:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800045c0:	0001e917          	auipc	s2,0x1e
    800045c4:	81090913          	addi	s2,s2,-2032 # 80021dd0 <log>
    800045c8:	01892583          	lw	a1,24(s2)
    800045cc:	02892503          	lw	a0,40(s2)
    800045d0:	fffff097          	auipc	ra,0xfffff
    800045d4:	fea080e7          	jalr	-22(ra) # 800035ba <bread>
    800045d8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800045da:	02c92683          	lw	a3,44(s2)
    800045de:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800045e0:	02d05763          	blez	a3,8000460e <write_head+0x5a>
    800045e4:	0001e797          	auipc	a5,0x1e
    800045e8:	81c78793          	addi	a5,a5,-2020 # 80021e00 <log+0x30>
    800045ec:	05c50713          	addi	a4,a0,92
    800045f0:	36fd                	addiw	a3,a3,-1
    800045f2:	1682                	slli	a3,a3,0x20
    800045f4:	9281                	srli	a3,a3,0x20
    800045f6:	068a                	slli	a3,a3,0x2
    800045f8:	0001e617          	auipc	a2,0x1e
    800045fc:	80c60613          	addi	a2,a2,-2036 # 80021e04 <log+0x34>
    80004600:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004602:	4390                	lw	a2,0(a5)
    80004604:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004606:	0791                	addi	a5,a5,4
    80004608:	0711                	addi	a4,a4,4
    8000460a:	fed79ce3          	bne	a5,a3,80004602 <write_head+0x4e>
  }
  bwrite(buf);
    8000460e:	8526                	mv	a0,s1
    80004610:	fffff097          	auipc	ra,0xfffff
    80004614:	09c080e7          	jalr	156(ra) # 800036ac <bwrite>
  brelse(buf);
    80004618:	8526                	mv	a0,s1
    8000461a:	fffff097          	auipc	ra,0xfffff
    8000461e:	0d0080e7          	jalr	208(ra) # 800036ea <brelse>
}
    80004622:	60e2                	ld	ra,24(sp)
    80004624:	6442                	ld	s0,16(sp)
    80004626:	64a2                	ld	s1,8(sp)
    80004628:	6902                	ld	s2,0(sp)
    8000462a:	6105                	addi	sp,sp,32
    8000462c:	8082                	ret

000000008000462e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000462e:	0001d797          	auipc	a5,0x1d
    80004632:	7ce7a783          	lw	a5,1998(a5) # 80021dfc <log+0x2c>
    80004636:	0af05d63          	blez	a5,800046f0 <install_trans+0xc2>
{
    8000463a:	7139                	addi	sp,sp,-64
    8000463c:	fc06                	sd	ra,56(sp)
    8000463e:	f822                	sd	s0,48(sp)
    80004640:	f426                	sd	s1,40(sp)
    80004642:	f04a                	sd	s2,32(sp)
    80004644:	ec4e                	sd	s3,24(sp)
    80004646:	e852                	sd	s4,16(sp)
    80004648:	e456                	sd	s5,8(sp)
    8000464a:	e05a                	sd	s6,0(sp)
    8000464c:	0080                	addi	s0,sp,64
    8000464e:	8b2a                	mv	s6,a0
    80004650:	0001da97          	auipc	s5,0x1d
    80004654:	7b0a8a93          	addi	s5,s5,1968 # 80021e00 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004658:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000465a:	0001d997          	auipc	s3,0x1d
    8000465e:	77698993          	addi	s3,s3,1910 # 80021dd0 <log>
    80004662:	a035                	j	8000468e <install_trans+0x60>
      bunpin(dbuf);
    80004664:	8526                	mv	a0,s1
    80004666:	fffff097          	auipc	ra,0xfffff
    8000466a:	15e080e7          	jalr	350(ra) # 800037c4 <bunpin>
    brelse(lbuf);
    8000466e:	854a                	mv	a0,s2
    80004670:	fffff097          	auipc	ra,0xfffff
    80004674:	07a080e7          	jalr	122(ra) # 800036ea <brelse>
    brelse(dbuf);
    80004678:	8526                	mv	a0,s1
    8000467a:	fffff097          	auipc	ra,0xfffff
    8000467e:	070080e7          	jalr	112(ra) # 800036ea <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004682:	2a05                	addiw	s4,s4,1
    80004684:	0a91                	addi	s5,s5,4
    80004686:	02c9a783          	lw	a5,44(s3)
    8000468a:	04fa5963          	bge	s4,a5,800046dc <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000468e:	0189a583          	lw	a1,24(s3)
    80004692:	014585bb          	addw	a1,a1,s4
    80004696:	2585                	addiw	a1,a1,1
    80004698:	0289a503          	lw	a0,40(s3)
    8000469c:	fffff097          	auipc	ra,0xfffff
    800046a0:	f1e080e7          	jalr	-226(ra) # 800035ba <bread>
    800046a4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800046a6:	000aa583          	lw	a1,0(s5)
    800046aa:	0289a503          	lw	a0,40(s3)
    800046ae:	fffff097          	auipc	ra,0xfffff
    800046b2:	f0c080e7          	jalr	-244(ra) # 800035ba <bread>
    800046b6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800046b8:	40000613          	li	a2,1024
    800046bc:	05890593          	addi	a1,s2,88
    800046c0:	05850513          	addi	a0,a0,88
    800046c4:	ffffc097          	auipc	ra,0xffffc
    800046c8:	682080e7          	jalr	1666(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    800046cc:	8526                	mv	a0,s1
    800046ce:	fffff097          	auipc	ra,0xfffff
    800046d2:	fde080e7          	jalr	-34(ra) # 800036ac <bwrite>
    if(recovering == 0)
    800046d6:	f80b1ce3          	bnez	s6,8000466e <install_trans+0x40>
    800046da:	b769                	j	80004664 <install_trans+0x36>
}
    800046dc:	70e2                	ld	ra,56(sp)
    800046de:	7442                	ld	s0,48(sp)
    800046e0:	74a2                	ld	s1,40(sp)
    800046e2:	7902                	ld	s2,32(sp)
    800046e4:	69e2                	ld	s3,24(sp)
    800046e6:	6a42                	ld	s4,16(sp)
    800046e8:	6aa2                	ld	s5,8(sp)
    800046ea:	6b02                	ld	s6,0(sp)
    800046ec:	6121                	addi	sp,sp,64
    800046ee:	8082                	ret
    800046f0:	8082                	ret

00000000800046f2 <initlog>:
{
    800046f2:	7179                	addi	sp,sp,-48
    800046f4:	f406                	sd	ra,40(sp)
    800046f6:	f022                	sd	s0,32(sp)
    800046f8:	ec26                	sd	s1,24(sp)
    800046fa:	e84a                	sd	s2,16(sp)
    800046fc:	e44e                	sd	s3,8(sp)
    800046fe:	1800                	addi	s0,sp,48
    80004700:	892a                	mv	s2,a0
    80004702:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004704:	0001d497          	auipc	s1,0x1d
    80004708:	6cc48493          	addi	s1,s1,1740 # 80021dd0 <log>
    8000470c:	00004597          	auipc	a1,0x4
    80004710:	07458593          	addi	a1,a1,116 # 80008780 <syscalls+0x208>
    80004714:	8526                	mv	a0,s1
    80004716:	ffffc097          	auipc	ra,0xffffc
    8000471a:	444080e7          	jalr	1092(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    8000471e:	0149a583          	lw	a1,20(s3)
    80004722:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004724:	0109a783          	lw	a5,16(s3)
    80004728:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000472a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000472e:	854a                	mv	a0,s2
    80004730:	fffff097          	auipc	ra,0xfffff
    80004734:	e8a080e7          	jalr	-374(ra) # 800035ba <bread>
  log.lh.n = lh->n;
    80004738:	4d3c                	lw	a5,88(a0)
    8000473a:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000473c:	02f05563          	blez	a5,80004766 <initlog+0x74>
    80004740:	05c50713          	addi	a4,a0,92
    80004744:	0001d697          	auipc	a3,0x1d
    80004748:	6bc68693          	addi	a3,a3,1724 # 80021e00 <log+0x30>
    8000474c:	37fd                	addiw	a5,a5,-1
    8000474e:	1782                	slli	a5,a5,0x20
    80004750:	9381                	srli	a5,a5,0x20
    80004752:	078a                	slli	a5,a5,0x2
    80004754:	06050613          	addi	a2,a0,96
    80004758:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000475a:	4310                	lw	a2,0(a4)
    8000475c:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000475e:	0711                	addi	a4,a4,4
    80004760:	0691                	addi	a3,a3,4
    80004762:	fef71ce3          	bne	a4,a5,8000475a <initlog+0x68>
  brelse(buf);
    80004766:	fffff097          	auipc	ra,0xfffff
    8000476a:	f84080e7          	jalr	-124(ra) # 800036ea <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000476e:	4505                	li	a0,1
    80004770:	00000097          	auipc	ra,0x0
    80004774:	ebe080e7          	jalr	-322(ra) # 8000462e <install_trans>
  log.lh.n = 0;
    80004778:	0001d797          	auipc	a5,0x1d
    8000477c:	6807a223          	sw	zero,1668(a5) # 80021dfc <log+0x2c>
  write_head(); // clear the log
    80004780:	00000097          	auipc	ra,0x0
    80004784:	e34080e7          	jalr	-460(ra) # 800045b4 <write_head>
}
    80004788:	70a2                	ld	ra,40(sp)
    8000478a:	7402                	ld	s0,32(sp)
    8000478c:	64e2                	ld	s1,24(sp)
    8000478e:	6942                	ld	s2,16(sp)
    80004790:	69a2                	ld	s3,8(sp)
    80004792:	6145                	addi	sp,sp,48
    80004794:	8082                	ret

0000000080004796 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004796:	1101                	addi	sp,sp,-32
    80004798:	ec06                	sd	ra,24(sp)
    8000479a:	e822                	sd	s0,16(sp)
    8000479c:	e426                	sd	s1,8(sp)
    8000479e:	e04a                	sd	s2,0(sp)
    800047a0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800047a2:	0001d517          	auipc	a0,0x1d
    800047a6:	62e50513          	addi	a0,a0,1582 # 80021dd0 <log>
    800047aa:	ffffc097          	auipc	ra,0xffffc
    800047ae:	440080e7          	jalr	1088(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    800047b2:	0001d497          	auipc	s1,0x1d
    800047b6:	61e48493          	addi	s1,s1,1566 # 80021dd0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800047ba:	4979                	li	s2,30
    800047bc:	a039                	j	800047ca <begin_op+0x34>
      sleep(&log, &log.lock);
    800047be:	85a6                	mv	a1,s1
    800047c0:	8526                	mv	a0,s1
    800047c2:	ffffe097          	auipc	ra,0xffffe
    800047c6:	bc4080e7          	jalr	-1084(ra) # 80002386 <sleep>
    if(log.committing){
    800047ca:	50dc                	lw	a5,36(s1)
    800047cc:	fbed                	bnez	a5,800047be <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800047ce:	509c                	lw	a5,32(s1)
    800047d0:	0017871b          	addiw	a4,a5,1
    800047d4:	0007069b          	sext.w	a3,a4
    800047d8:	0027179b          	slliw	a5,a4,0x2
    800047dc:	9fb9                	addw	a5,a5,a4
    800047de:	0017979b          	slliw	a5,a5,0x1
    800047e2:	54d8                	lw	a4,44(s1)
    800047e4:	9fb9                	addw	a5,a5,a4
    800047e6:	00f95963          	bge	s2,a5,800047f8 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800047ea:	85a6                	mv	a1,s1
    800047ec:	8526                	mv	a0,s1
    800047ee:	ffffe097          	auipc	ra,0xffffe
    800047f2:	b98080e7          	jalr	-1128(ra) # 80002386 <sleep>
    800047f6:	bfd1                	j	800047ca <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800047f8:	0001d517          	auipc	a0,0x1d
    800047fc:	5d850513          	addi	a0,a0,1496 # 80021dd0 <log>
    80004800:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004802:	ffffc097          	auipc	ra,0xffffc
    80004806:	49c080e7          	jalr	1180(ra) # 80000c9e <release>
      break;
    }
  }
}
    8000480a:	60e2                	ld	ra,24(sp)
    8000480c:	6442                	ld	s0,16(sp)
    8000480e:	64a2                	ld	s1,8(sp)
    80004810:	6902                	ld	s2,0(sp)
    80004812:	6105                	addi	sp,sp,32
    80004814:	8082                	ret

0000000080004816 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004816:	7139                	addi	sp,sp,-64
    80004818:	fc06                	sd	ra,56(sp)
    8000481a:	f822                	sd	s0,48(sp)
    8000481c:	f426                	sd	s1,40(sp)
    8000481e:	f04a                	sd	s2,32(sp)
    80004820:	ec4e                	sd	s3,24(sp)
    80004822:	e852                	sd	s4,16(sp)
    80004824:	e456                	sd	s5,8(sp)
    80004826:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004828:	0001d497          	auipc	s1,0x1d
    8000482c:	5a848493          	addi	s1,s1,1448 # 80021dd0 <log>
    80004830:	8526                	mv	a0,s1
    80004832:	ffffc097          	auipc	ra,0xffffc
    80004836:	3b8080e7          	jalr	952(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    8000483a:	509c                	lw	a5,32(s1)
    8000483c:	37fd                	addiw	a5,a5,-1
    8000483e:	0007891b          	sext.w	s2,a5
    80004842:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004844:	50dc                	lw	a5,36(s1)
    80004846:	efb9                	bnez	a5,800048a4 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004848:	06091663          	bnez	s2,800048b4 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000484c:	0001d497          	auipc	s1,0x1d
    80004850:	58448493          	addi	s1,s1,1412 # 80021dd0 <log>
    80004854:	4785                	li	a5,1
    80004856:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004858:	8526                	mv	a0,s1
    8000485a:	ffffc097          	auipc	ra,0xffffc
    8000485e:	444080e7          	jalr	1092(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004862:	54dc                	lw	a5,44(s1)
    80004864:	06f04763          	bgtz	a5,800048d2 <end_op+0xbc>
    acquire(&log.lock);
    80004868:	0001d497          	auipc	s1,0x1d
    8000486c:	56848493          	addi	s1,s1,1384 # 80021dd0 <log>
    80004870:	8526                	mv	a0,s1
    80004872:	ffffc097          	auipc	ra,0xffffc
    80004876:	378080e7          	jalr	888(ra) # 80000bea <acquire>
    log.committing = 0;
    8000487a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000487e:	8526                	mv	a0,s1
    80004880:	ffffe097          	auipc	ra,0xffffe
    80004884:	cb6080e7          	jalr	-842(ra) # 80002536 <wakeup>
    release(&log.lock);
    80004888:	8526                	mv	a0,s1
    8000488a:	ffffc097          	auipc	ra,0xffffc
    8000488e:	414080e7          	jalr	1044(ra) # 80000c9e <release>
}
    80004892:	70e2                	ld	ra,56(sp)
    80004894:	7442                	ld	s0,48(sp)
    80004896:	74a2                	ld	s1,40(sp)
    80004898:	7902                	ld	s2,32(sp)
    8000489a:	69e2                	ld	s3,24(sp)
    8000489c:	6a42                	ld	s4,16(sp)
    8000489e:	6aa2                	ld	s5,8(sp)
    800048a0:	6121                	addi	sp,sp,64
    800048a2:	8082                	ret
    panic("log.committing");
    800048a4:	00004517          	auipc	a0,0x4
    800048a8:	ee450513          	addi	a0,a0,-284 # 80008788 <syscalls+0x210>
    800048ac:	ffffc097          	auipc	ra,0xffffc
    800048b0:	c98080e7          	jalr	-872(ra) # 80000544 <panic>
    wakeup(&log);
    800048b4:	0001d497          	auipc	s1,0x1d
    800048b8:	51c48493          	addi	s1,s1,1308 # 80021dd0 <log>
    800048bc:	8526                	mv	a0,s1
    800048be:	ffffe097          	auipc	ra,0xffffe
    800048c2:	c78080e7          	jalr	-904(ra) # 80002536 <wakeup>
  release(&log.lock);
    800048c6:	8526                	mv	a0,s1
    800048c8:	ffffc097          	auipc	ra,0xffffc
    800048cc:	3d6080e7          	jalr	982(ra) # 80000c9e <release>
  if(do_commit){
    800048d0:	b7c9                	j	80004892 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048d2:	0001da97          	auipc	s5,0x1d
    800048d6:	52ea8a93          	addi	s5,s5,1326 # 80021e00 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800048da:	0001da17          	auipc	s4,0x1d
    800048de:	4f6a0a13          	addi	s4,s4,1270 # 80021dd0 <log>
    800048e2:	018a2583          	lw	a1,24(s4)
    800048e6:	012585bb          	addw	a1,a1,s2
    800048ea:	2585                	addiw	a1,a1,1
    800048ec:	028a2503          	lw	a0,40(s4)
    800048f0:	fffff097          	auipc	ra,0xfffff
    800048f4:	cca080e7          	jalr	-822(ra) # 800035ba <bread>
    800048f8:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800048fa:	000aa583          	lw	a1,0(s5)
    800048fe:	028a2503          	lw	a0,40(s4)
    80004902:	fffff097          	auipc	ra,0xfffff
    80004906:	cb8080e7          	jalr	-840(ra) # 800035ba <bread>
    8000490a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000490c:	40000613          	li	a2,1024
    80004910:	05850593          	addi	a1,a0,88
    80004914:	05848513          	addi	a0,s1,88
    80004918:	ffffc097          	auipc	ra,0xffffc
    8000491c:	42e080e7          	jalr	1070(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    80004920:	8526                	mv	a0,s1
    80004922:	fffff097          	auipc	ra,0xfffff
    80004926:	d8a080e7          	jalr	-630(ra) # 800036ac <bwrite>
    brelse(from);
    8000492a:	854e                	mv	a0,s3
    8000492c:	fffff097          	auipc	ra,0xfffff
    80004930:	dbe080e7          	jalr	-578(ra) # 800036ea <brelse>
    brelse(to);
    80004934:	8526                	mv	a0,s1
    80004936:	fffff097          	auipc	ra,0xfffff
    8000493a:	db4080e7          	jalr	-588(ra) # 800036ea <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000493e:	2905                	addiw	s2,s2,1
    80004940:	0a91                	addi	s5,s5,4
    80004942:	02ca2783          	lw	a5,44(s4)
    80004946:	f8f94ee3          	blt	s2,a5,800048e2 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000494a:	00000097          	auipc	ra,0x0
    8000494e:	c6a080e7          	jalr	-918(ra) # 800045b4 <write_head>
    install_trans(0); // Now install writes to home locations
    80004952:	4501                	li	a0,0
    80004954:	00000097          	auipc	ra,0x0
    80004958:	cda080e7          	jalr	-806(ra) # 8000462e <install_trans>
    log.lh.n = 0;
    8000495c:	0001d797          	auipc	a5,0x1d
    80004960:	4a07a023          	sw	zero,1184(a5) # 80021dfc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004964:	00000097          	auipc	ra,0x0
    80004968:	c50080e7          	jalr	-944(ra) # 800045b4 <write_head>
    8000496c:	bdf5                	j	80004868 <end_op+0x52>

000000008000496e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000496e:	1101                	addi	sp,sp,-32
    80004970:	ec06                	sd	ra,24(sp)
    80004972:	e822                	sd	s0,16(sp)
    80004974:	e426                	sd	s1,8(sp)
    80004976:	e04a                	sd	s2,0(sp)
    80004978:	1000                	addi	s0,sp,32
    8000497a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000497c:	0001d917          	auipc	s2,0x1d
    80004980:	45490913          	addi	s2,s2,1108 # 80021dd0 <log>
    80004984:	854a                	mv	a0,s2
    80004986:	ffffc097          	auipc	ra,0xffffc
    8000498a:	264080e7          	jalr	612(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000498e:	02c92603          	lw	a2,44(s2)
    80004992:	47f5                	li	a5,29
    80004994:	06c7c563          	blt	a5,a2,800049fe <log_write+0x90>
    80004998:	0001d797          	auipc	a5,0x1d
    8000499c:	4547a783          	lw	a5,1108(a5) # 80021dec <log+0x1c>
    800049a0:	37fd                	addiw	a5,a5,-1
    800049a2:	04f65e63          	bge	a2,a5,800049fe <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800049a6:	0001d797          	auipc	a5,0x1d
    800049aa:	44a7a783          	lw	a5,1098(a5) # 80021df0 <log+0x20>
    800049ae:	06f05063          	blez	a5,80004a0e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800049b2:	4781                	li	a5,0
    800049b4:	06c05563          	blez	a2,80004a1e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800049b8:	44cc                	lw	a1,12(s1)
    800049ba:	0001d717          	auipc	a4,0x1d
    800049be:	44670713          	addi	a4,a4,1094 # 80021e00 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800049c2:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800049c4:	4314                	lw	a3,0(a4)
    800049c6:	04b68c63          	beq	a3,a1,80004a1e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800049ca:	2785                	addiw	a5,a5,1
    800049cc:	0711                	addi	a4,a4,4
    800049ce:	fef61be3          	bne	a2,a5,800049c4 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800049d2:	0621                	addi	a2,a2,8
    800049d4:	060a                	slli	a2,a2,0x2
    800049d6:	0001d797          	auipc	a5,0x1d
    800049da:	3fa78793          	addi	a5,a5,1018 # 80021dd0 <log>
    800049de:	963e                	add	a2,a2,a5
    800049e0:	44dc                	lw	a5,12(s1)
    800049e2:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800049e4:	8526                	mv	a0,s1
    800049e6:	fffff097          	auipc	ra,0xfffff
    800049ea:	da2080e7          	jalr	-606(ra) # 80003788 <bpin>
    log.lh.n++;
    800049ee:	0001d717          	auipc	a4,0x1d
    800049f2:	3e270713          	addi	a4,a4,994 # 80021dd0 <log>
    800049f6:	575c                	lw	a5,44(a4)
    800049f8:	2785                	addiw	a5,a5,1
    800049fa:	d75c                	sw	a5,44(a4)
    800049fc:	a835                	j	80004a38 <log_write+0xca>
    panic("too big a transaction");
    800049fe:	00004517          	auipc	a0,0x4
    80004a02:	d9a50513          	addi	a0,a0,-614 # 80008798 <syscalls+0x220>
    80004a06:	ffffc097          	auipc	ra,0xffffc
    80004a0a:	b3e080e7          	jalr	-1218(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    80004a0e:	00004517          	auipc	a0,0x4
    80004a12:	da250513          	addi	a0,a0,-606 # 800087b0 <syscalls+0x238>
    80004a16:	ffffc097          	auipc	ra,0xffffc
    80004a1a:	b2e080e7          	jalr	-1234(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    80004a1e:	00878713          	addi	a4,a5,8
    80004a22:	00271693          	slli	a3,a4,0x2
    80004a26:	0001d717          	auipc	a4,0x1d
    80004a2a:	3aa70713          	addi	a4,a4,938 # 80021dd0 <log>
    80004a2e:	9736                	add	a4,a4,a3
    80004a30:	44d4                	lw	a3,12(s1)
    80004a32:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004a34:	faf608e3          	beq	a2,a5,800049e4 <log_write+0x76>
  }
  release(&log.lock);
    80004a38:	0001d517          	auipc	a0,0x1d
    80004a3c:	39850513          	addi	a0,a0,920 # 80021dd0 <log>
    80004a40:	ffffc097          	auipc	ra,0xffffc
    80004a44:	25e080e7          	jalr	606(ra) # 80000c9e <release>
}
    80004a48:	60e2                	ld	ra,24(sp)
    80004a4a:	6442                	ld	s0,16(sp)
    80004a4c:	64a2                	ld	s1,8(sp)
    80004a4e:	6902                	ld	s2,0(sp)
    80004a50:	6105                	addi	sp,sp,32
    80004a52:	8082                	ret

0000000080004a54 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004a54:	1101                	addi	sp,sp,-32
    80004a56:	ec06                	sd	ra,24(sp)
    80004a58:	e822                	sd	s0,16(sp)
    80004a5a:	e426                	sd	s1,8(sp)
    80004a5c:	e04a                	sd	s2,0(sp)
    80004a5e:	1000                	addi	s0,sp,32
    80004a60:	84aa                	mv	s1,a0
    80004a62:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004a64:	00004597          	auipc	a1,0x4
    80004a68:	d6c58593          	addi	a1,a1,-660 # 800087d0 <syscalls+0x258>
    80004a6c:	0521                	addi	a0,a0,8
    80004a6e:	ffffc097          	auipc	ra,0xffffc
    80004a72:	0ec080e7          	jalr	236(ra) # 80000b5a <initlock>
  lk->name = name;
    80004a76:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004a7a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a7e:	0204a423          	sw	zero,40(s1)
}
    80004a82:	60e2                	ld	ra,24(sp)
    80004a84:	6442                	ld	s0,16(sp)
    80004a86:	64a2                	ld	s1,8(sp)
    80004a88:	6902                	ld	s2,0(sp)
    80004a8a:	6105                	addi	sp,sp,32
    80004a8c:	8082                	ret

0000000080004a8e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004a8e:	1101                	addi	sp,sp,-32
    80004a90:	ec06                	sd	ra,24(sp)
    80004a92:	e822                	sd	s0,16(sp)
    80004a94:	e426                	sd	s1,8(sp)
    80004a96:	e04a                	sd	s2,0(sp)
    80004a98:	1000                	addi	s0,sp,32
    80004a9a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a9c:	00850913          	addi	s2,a0,8
    80004aa0:	854a                	mv	a0,s2
    80004aa2:	ffffc097          	auipc	ra,0xffffc
    80004aa6:	148080e7          	jalr	328(ra) # 80000bea <acquire>
  while (lk->locked) {
    80004aaa:	409c                	lw	a5,0(s1)
    80004aac:	cb89                	beqz	a5,80004abe <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004aae:	85ca                	mv	a1,s2
    80004ab0:	8526                	mv	a0,s1
    80004ab2:	ffffe097          	auipc	ra,0xffffe
    80004ab6:	8d4080e7          	jalr	-1836(ra) # 80002386 <sleep>
  while (lk->locked) {
    80004aba:	409c                	lw	a5,0(s1)
    80004abc:	fbed                	bnez	a5,80004aae <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004abe:	4785                	li	a5,1
    80004ac0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004ac2:	ffffd097          	auipc	ra,0xffffd
    80004ac6:	f04080e7          	jalr	-252(ra) # 800019c6 <myproc>
    80004aca:	591c                	lw	a5,48(a0)
    80004acc:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004ace:	854a                	mv	a0,s2
    80004ad0:	ffffc097          	auipc	ra,0xffffc
    80004ad4:	1ce080e7          	jalr	462(ra) # 80000c9e <release>
}
    80004ad8:	60e2                	ld	ra,24(sp)
    80004ada:	6442                	ld	s0,16(sp)
    80004adc:	64a2                	ld	s1,8(sp)
    80004ade:	6902                	ld	s2,0(sp)
    80004ae0:	6105                	addi	sp,sp,32
    80004ae2:	8082                	ret

0000000080004ae4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004ae4:	1101                	addi	sp,sp,-32
    80004ae6:	ec06                	sd	ra,24(sp)
    80004ae8:	e822                	sd	s0,16(sp)
    80004aea:	e426                	sd	s1,8(sp)
    80004aec:	e04a                	sd	s2,0(sp)
    80004aee:	1000                	addi	s0,sp,32
    80004af0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004af2:	00850913          	addi	s2,a0,8
    80004af6:	854a                	mv	a0,s2
    80004af8:	ffffc097          	auipc	ra,0xffffc
    80004afc:	0f2080e7          	jalr	242(ra) # 80000bea <acquire>
  lk->locked = 0;
    80004b00:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b04:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004b08:	8526                	mv	a0,s1
    80004b0a:	ffffe097          	auipc	ra,0xffffe
    80004b0e:	a2c080e7          	jalr	-1492(ra) # 80002536 <wakeup>
  release(&lk->lk);
    80004b12:	854a                	mv	a0,s2
    80004b14:	ffffc097          	auipc	ra,0xffffc
    80004b18:	18a080e7          	jalr	394(ra) # 80000c9e <release>
}
    80004b1c:	60e2                	ld	ra,24(sp)
    80004b1e:	6442                	ld	s0,16(sp)
    80004b20:	64a2                	ld	s1,8(sp)
    80004b22:	6902                	ld	s2,0(sp)
    80004b24:	6105                	addi	sp,sp,32
    80004b26:	8082                	ret

0000000080004b28 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004b28:	7179                	addi	sp,sp,-48
    80004b2a:	f406                	sd	ra,40(sp)
    80004b2c:	f022                	sd	s0,32(sp)
    80004b2e:	ec26                	sd	s1,24(sp)
    80004b30:	e84a                	sd	s2,16(sp)
    80004b32:	e44e                	sd	s3,8(sp)
    80004b34:	1800                	addi	s0,sp,48
    80004b36:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004b38:	00850913          	addi	s2,a0,8
    80004b3c:	854a                	mv	a0,s2
    80004b3e:	ffffc097          	auipc	ra,0xffffc
    80004b42:	0ac080e7          	jalr	172(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b46:	409c                	lw	a5,0(s1)
    80004b48:	ef99                	bnez	a5,80004b66 <holdingsleep+0x3e>
    80004b4a:	4481                	li	s1,0
  release(&lk->lk);
    80004b4c:	854a                	mv	a0,s2
    80004b4e:	ffffc097          	auipc	ra,0xffffc
    80004b52:	150080e7          	jalr	336(ra) # 80000c9e <release>
  return r;
}
    80004b56:	8526                	mv	a0,s1
    80004b58:	70a2                	ld	ra,40(sp)
    80004b5a:	7402                	ld	s0,32(sp)
    80004b5c:	64e2                	ld	s1,24(sp)
    80004b5e:	6942                	ld	s2,16(sp)
    80004b60:	69a2                	ld	s3,8(sp)
    80004b62:	6145                	addi	sp,sp,48
    80004b64:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b66:	0284a983          	lw	s3,40(s1)
    80004b6a:	ffffd097          	auipc	ra,0xffffd
    80004b6e:	e5c080e7          	jalr	-420(ra) # 800019c6 <myproc>
    80004b72:	5904                	lw	s1,48(a0)
    80004b74:	413484b3          	sub	s1,s1,s3
    80004b78:	0014b493          	seqz	s1,s1
    80004b7c:	bfc1                	j	80004b4c <holdingsleep+0x24>

0000000080004b7e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004b7e:	1141                	addi	sp,sp,-16
    80004b80:	e406                	sd	ra,8(sp)
    80004b82:	e022                	sd	s0,0(sp)
    80004b84:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004b86:	00004597          	auipc	a1,0x4
    80004b8a:	c5a58593          	addi	a1,a1,-934 # 800087e0 <syscalls+0x268>
    80004b8e:	0001d517          	auipc	a0,0x1d
    80004b92:	38a50513          	addi	a0,a0,906 # 80021f18 <ftable>
    80004b96:	ffffc097          	auipc	ra,0xffffc
    80004b9a:	fc4080e7          	jalr	-60(ra) # 80000b5a <initlock>
}
    80004b9e:	60a2                	ld	ra,8(sp)
    80004ba0:	6402                	ld	s0,0(sp)
    80004ba2:	0141                	addi	sp,sp,16
    80004ba4:	8082                	ret

0000000080004ba6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004ba6:	1101                	addi	sp,sp,-32
    80004ba8:	ec06                	sd	ra,24(sp)
    80004baa:	e822                	sd	s0,16(sp)
    80004bac:	e426                	sd	s1,8(sp)
    80004bae:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004bb0:	0001d517          	auipc	a0,0x1d
    80004bb4:	36850513          	addi	a0,a0,872 # 80021f18 <ftable>
    80004bb8:	ffffc097          	auipc	ra,0xffffc
    80004bbc:	032080e7          	jalr	50(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004bc0:	0001d497          	auipc	s1,0x1d
    80004bc4:	37048493          	addi	s1,s1,880 # 80021f30 <ftable+0x18>
    80004bc8:	0001e717          	auipc	a4,0x1e
    80004bcc:	30870713          	addi	a4,a4,776 # 80022ed0 <disk>
    if(f->ref == 0){
    80004bd0:	40dc                	lw	a5,4(s1)
    80004bd2:	cf99                	beqz	a5,80004bf0 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004bd4:	02848493          	addi	s1,s1,40
    80004bd8:	fee49ce3          	bne	s1,a4,80004bd0 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004bdc:	0001d517          	auipc	a0,0x1d
    80004be0:	33c50513          	addi	a0,a0,828 # 80021f18 <ftable>
    80004be4:	ffffc097          	auipc	ra,0xffffc
    80004be8:	0ba080e7          	jalr	186(ra) # 80000c9e <release>
  return 0;
    80004bec:	4481                	li	s1,0
    80004bee:	a819                	j	80004c04 <filealloc+0x5e>
      f->ref = 1;
    80004bf0:	4785                	li	a5,1
    80004bf2:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004bf4:	0001d517          	auipc	a0,0x1d
    80004bf8:	32450513          	addi	a0,a0,804 # 80021f18 <ftable>
    80004bfc:	ffffc097          	auipc	ra,0xffffc
    80004c00:	0a2080e7          	jalr	162(ra) # 80000c9e <release>
}
    80004c04:	8526                	mv	a0,s1
    80004c06:	60e2                	ld	ra,24(sp)
    80004c08:	6442                	ld	s0,16(sp)
    80004c0a:	64a2                	ld	s1,8(sp)
    80004c0c:	6105                	addi	sp,sp,32
    80004c0e:	8082                	ret

0000000080004c10 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004c10:	1101                	addi	sp,sp,-32
    80004c12:	ec06                	sd	ra,24(sp)
    80004c14:	e822                	sd	s0,16(sp)
    80004c16:	e426                	sd	s1,8(sp)
    80004c18:	1000                	addi	s0,sp,32
    80004c1a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004c1c:	0001d517          	auipc	a0,0x1d
    80004c20:	2fc50513          	addi	a0,a0,764 # 80021f18 <ftable>
    80004c24:	ffffc097          	auipc	ra,0xffffc
    80004c28:	fc6080e7          	jalr	-58(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004c2c:	40dc                	lw	a5,4(s1)
    80004c2e:	02f05263          	blez	a5,80004c52 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004c32:	2785                	addiw	a5,a5,1
    80004c34:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004c36:	0001d517          	auipc	a0,0x1d
    80004c3a:	2e250513          	addi	a0,a0,738 # 80021f18 <ftable>
    80004c3e:	ffffc097          	auipc	ra,0xffffc
    80004c42:	060080e7          	jalr	96(ra) # 80000c9e <release>
  return f;
}
    80004c46:	8526                	mv	a0,s1
    80004c48:	60e2                	ld	ra,24(sp)
    80004c4a:	6442                	ld	s0,16(sp)
    80004c4c:	64a2                	ld	s1,8(sp)
    80004c4e:	6105                	addi	sp,sp,32
    80004c50:	8082                	ret
    panic("filedup");
    80004c52:	00004517          	auipc	a0,0x4
    80004c56:	b9650513          	addi	a0,a0,-1130 # 800087e8 <syscalls+0x270>
    80004c5a:	ffffc097          	auipc	ra,0xffffc
    80004c5e:	8ea080e7          	jalr	-1814(ra) # 80000544 <panic>

0000000080004c62 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004c62:	7139                	addi	sp,sp,-64
    80004c64:	fc06                	sd	ra,56(sp)
    80004c66:	f822                	sd	s0,48(sp)
    80004c68:	f426                	sd	s1,40(sp)
    80004c6a:	f04a                	sd	s2,32(sp)
    80004c6c:	ec4e                	sd	s3,24(sp)
    80004c6e:	e852                	sd	s4,16(sp)
    80004c70:	e456                	sd	s5,8(sp)
    80004c72:	0080                	addi	s0,sp,64
    80004c74:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004c76:	0001d517          	auipc	a0,0x1d
    80004c7a:	2a250513          	addi	a0,a0,674 # 80021f18 <ftable>
    80004c7e:	ffffc097          	auipc	ra,0xffffc
    80004c82:	f6c080e7          	jalr	-148(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004c86:	40dc                	lw	a5,4(s1)
    80004c88:	06f05163          	blez	a5,80004cea <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004c8c:	37fd                	addiw	a5,a5,-1
    80004c8e:	0007871b          	sext.w	a4,a5
    80004c92:	c0dc                	sw	a5,4(s1)
    80004c94:	06e04363          	bgtz	a4,80004cfa <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004c98:	0004a903          	lw	s2,0(s1)
    80004c9c:	0094ca83          	lbu	s5,9(s1)
    80004ca0:	0104ba03          	ld	s4,16(s1)
    80004ca4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004ca8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004cac:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004cb0:	0001d517          	auipc	a0,0x1d
    80004cb4:	26850513          	addi	a0,a0,616 # 80021f18 <ftable>
    80004cb8:	ffffc097          	auipc	ra,0xffffc
    80004cbc:	fe6080e7          	jalr	-26(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    80004cc0:	4785                	li	a5,1
    80004cc2:	04f90d63          	beq	s2,a5,80004d1c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004cc6:	3979                	addiw	s2,s2,-2
    80004cc8:	4785                	li	a5,1
    80004cca:	0527e063          	bltu	a5,s2,80004d0a <fileclose+0xa8>
    begin_op();
    80004cce:	00000097          	auipc	ra,0x0
    80004cd2:	ac8080e7          	jalr	-1336(ra) # 80004796 <begin_op>
    iput(ff.ip);
    80004cd6:	854e                	mv	a0,s3
    80004cd8:	fffff097          	auipc	ra,0xfffff
    80004cdc:	2b6080e7          	jalr	694(ra) # 80003f8e <iput>
    end_op();
    80004ce0:	00000097          	auipc	ra,0x0
    80004ce4:	b36080e7          	jalr	-1226(ra) # 80004816 <end_op>
    80004ce8:	a00d                	j	80004d0a <fileclose+0xa8>
    panic("fileclose");
    80004cea:	00004517          	auipc	a0,0x4
    80004cee:	b0650513          	addi	a0,a0,-1274 # 800087f0 <syscalls+0x278>
    80004cf2:	ffffc097          	auipc	ra,0xffffc
    80004cf6:	852080e7          	jalr	-1966(ra) # 80000544 <panic>
    release(&ftable.lock);
    80004cfa:	0001d517          	auipc	a0,0x1d
    80004cfe:	21e50513          	addi	a0,a0,542 # 80021f18 <ftable>
    80004d02:	ffffc097          	auipc	ra,0xffffc
    80004d06:	f9c080e7          	jalr	-100(ra) # 80000c9e <release>
  }
}
    80004d0a:	70e2                	ld	ra,56(sp)
    80004d0c:	7442                	ld	s0,48(sp)
    80004d0e:	74a2                	ld	s1,40(sp)
    80004d10:	7902                	ld	s2,32(sp)
    80004d12:	69e2                	ld	s3,24(sp)
    80004d14:	6a42                	ld	s4,16(sp)
    80004d16:	6aa2                	ld	s5,8(sp)
    80004d18:	6121                	addi	sp,sp,64
    80004d1a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004d1c:	85d6                	mv	a1,s5
    80004d1e:	8552                	mv	a0,s4
    80004d20:	00000097          	auipc	ra,0x0
    80004d24:	34c080e7          	jalr	844(ra) # 8000506c <pipeclose>
    80004d28:	b7cd                	j	80004d0a <fileclose+0xa8>

0000000080004d2a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004d2a:	715d                	addi	sp,sp,-80
    80004d2c:	e486                	sd	ra,72(sp)
    80004d2e:	e0a2                	sd	s0,64(sp)
    80004d30:	fc26                	sd	s1,56(sp)
    80004d32:	f84a                	sd	s2,48(sp)
    80004d34:	f44e                	sd	s3,40(sp)
    80004d36:	0880                	addi	s0,sp,80
    80004d38:	84aa                	mv	s1,a0
    80004d3a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004d3c:	ffffd097          	auipc	ra,0xffffd
    80004d40:	c8a080e7          	jalr	-886(ra) # 800019c6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004d44:	409c                	lw	a5,0(s1)
    80004d46:	37f9                	addiw	a5,a5,-2
    80004d48:	4705                	li	a4,1
    80004d4a:	04f76763          	bltu	a4,a5,80004d98 <filestat+0x6e>
    80004d4e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004d50:	6c88                	ld	a0,24(s1)
    80004d52:	fffff097          	auipc	ra,0xfffff
    80004d56:	082080e7          	jalr	130(ra) # 80003dd4 <ilock>
    stati(f->ip, &st);
    80004d5a:	fb840593          	addi	a1,s0,-72
    80004d5e:	6c88                	ld	a0,24(s1)
    80004d60:	fffff097          	auipc	ra,0xfffff
    80004d64:	2fe080e7          	jalr	766(ra) # 8000405e <stati>
    iunlock(f->ip);
    80004d68:	6c88                	ld	a0,24(s1)
    80004d6a:	fffff097          	auipc	ra,0xfffff
    80004d6e:	12c080e7          	jalr	300(ra) # 80003e96 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004d72:	46e1                	li	a3,24
    80004d74:	fb840613          	addi	a2,s0,-72
    80004d78:	85ce                	mv	a1,s3
    80004d7a:	05093503          	ld	a0,80(s2)
    80004d7e:	ffffd097          	auipc	ra,0xffffd
    80004d82:	906080e7          	jalr	-1786(ra) # 80001684 <copyout>
    80004d86:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004d8a:	60a6                	ld	ra,72(sp)
    80004d8c:	6406                	ld	s0,64(sp)
    80004d8e:	74e2                	ld	s1,56(sp)
    80004d90:	7942                	ld	s2,48(sp)
    80004d92:	79a2                	ld	s3,40(sp)
    80004d94:	6161                	addi	sp,sp,80
    80004d96:	8082                	ret
  return -1;
    80004d98:	557d                	li	a0,-1
    80004d9a:	bfc5                	j	80004d8a <filestat+0x60>

0000000080004d9c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004d9c:	7179                	addi	sp,sp,-48
    80004d9e:	f406                	sd	ra,40(sp)
    80004da0:	f022                	sd	s0,32(sp)
    80004da2:	ec26                	sd	s1,24(sp)
    80004da4:	e84a                	sd	s2,16(sp)
    80004da6:	e44e                	sd	s3,8(sp)
    80004da8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004daa:	00854783          	lbu	a5,8(a0)
    80004dae:	c3d5                	beqz	a5,80004e52 <fileread+0xb6>
    80004db0:	84aa                	mv	s1,a0
    80004db2:	89ae                	mv	s3,a1
    80004db4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004db6:	411c                	lw	a5,0(a0)
    80004db8:	4705                	li	a4,1
    80004dba:	04e78963          	beq	a5,a4,80004e0c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004dbe:	470d                	li	a4,3
    80004dc0:	04e78d63          	beq	a5,a4,80004e1a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004dc4:	4709                	li	a4,2
    80004dc6:	06e79e63          	bne	a5,a4,80004e42 <fileread+0xa6>
    ilock(f->ip);
    80004dca:	6d08                	ld	a0,24(a0)
    80004dcc:	fffff097          	auipc	ra,0xfffff
    80004dd0:	008080e7          	jalr	8(ra) # 80003dd4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004dd4:	874a                	mv	a4,s2
    80004dd6:	5094                	lw	a3,32(s1)
    80004dd8:	864e                	mv	a2,s3
    80004dda:	4585                	li	a1,1
    80004ddc:	6c88                	ld	a0,24(s1)
    80004dde:	fffff097          	auipc	ra,0xfffff
    80004de2:	2aa080e7          	jalr	682(ra) # 80004088 <readi>
    80004de6:	892a                	mv	s2,a0
    80004de8:	00a05563          	blez	a0,80004df2 <fileread+0x56>
      f->off += r;
    80004dec:	509c                	lw	a5,32(s1)
    80004dee:	9fa9                	addw	a5,a5,a0
    80004df0:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004df2:	6c88                	ld	a0,24(s1)
    80004df4:	fffff097          	auipc	ra,0xfffff
    80004df8:	0a2080e7          	jalr	162(ra) # 80003e96 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004dfc:	854a                	mv	a0,s2
    80004dfe:	70a2                	ld	ra,40(sp)
    80004e00:	7402                	ld	s0,32(sp)
    80004e02:	64e2                	ld	s1,24(sp)
    80004e04:	6942                	ld	s2,16(sp)
    80004e06:	69a2                	ld	s3,8(sp)
    80004e08:	6145                	addi	sp,sp,48
    80004e0a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004e0c:	6908                	ld	a0,16(a0)
    80004e0e:	00000097          	auipc	ra,0x0
    80004e12:	3ce080e7          	jalr	974(ra) # 800051dc <piperead>
    80004e16:	892a                	mv	s2,a0
    80004e18:	b7d5                	j	80004dfc <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004e1a:	02451783          	lh	a5,36(a0)
    80004e1e:	03079693          	slli	a3,a5,0x30
    80004e22:	92c1                	srli	a3,a3,0x30
    80004e24:	4725                	li	a4,9
    80004e26:	02d76863          	bltu	a4,a3,80004e56 <fileread+0xba>
    80004e2a:	0792                	slli	a5,a5,0x4
    80004e2c:	0001d717          	auipc	a4,0x1d
    80004e30:	04c70713          	addi	a4,a4,76 # 80021e78 <devsw>
    80004e34:	97ba                	add	a5,a5,a4
    80004e36:	639c                	ld	a5,0(a5)
    80004e38:	c38d                	beqz	a5,80004e5a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004e3a:	4505                	li	a0,1
    80004e3c:	9782                	jalr	a5
    80004e3e:	892a                	mv	s2,a0
    80004e40:	bf75                	j	80004dfc <fileread+0x60>
    panic("fileread");
    80004e42:	00004517          	auipc	a0,0x4
    80004e46:	9be50513          	addi	a0,a0,-1602 # 80008800 <syscalls+0x288>
    80004e4a:	ffffb097          	auipc	ra,0xffffb
    80004e4e:	6fa080e7          	jalr	1786(ra) # 80000544 <panic>
    return -1;
    80004e52:	597d                	li	s2,-1
    80004e54:	b765                	j	80004dfc <fileread+0x60>
      return -1;
    80004e56:	597d                	li	s2,-1
    80004e58:	b755                	j	80004dfc <fileread+0x60>
    80004e5a:	597d                	li	s2,-1
    80004e5c:	b745                	j	80004dfc <fileread+0x60>

0000000080004e5e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004e5e:	715d                	addi	sp,sp,-80
    80004e60:	e486                	sd	ra,72(sp)
    80004e62:	e0a2                	sd	s0,64(sp)
    80004e64:	fc26                	sd	s1,56(sp)
    80004e66:	f84a                	sd	s2,48(sp)
    80004e68:	f44e                	sd	s3,40(sp)
    80004e6a:	f052                	sd	s4,32(sp)
    80004e6c:	ec56                	sd	s5,24(sp)
    80004e6e:	e85a                	sd	s6,16(sp)
    80004e70:	e45e                	sd	s7,8(sp)
    80004e72:	e062                	sd	s8,0(sp)
    80004e74:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004e76:	00954783          	lbu	a5,9(a0)
    80004e7a:	10078663          	beqz	a5,80004f86 <filewrite+0x128>
    80004e7e:	892a                	mv	s2,a0
    80004e80:	8aae                	mv	s5,a1
    80004e82:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e84:	411c                	lw	a5,0(a0)
    80004e86:	4705                	li	a4,1
    80004e88:	02e78263          	beq	a5,a4,80004eac <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e8c:	470d                	li	a4,3
    80004e8e:	02e78663          	beq	a5,a4,80004eba <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e92:	4709                	li	a4,2
    80004e94:	0ee79163          	bne	a5,a4,80004f76 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004e98:	0ac05d63          	blez	a2,80004f52 <filewrite+0xf4>
    int i = 0;
    80004e9c:	4981                	li	s3,0
    80004e9e:	6b05                	lui	s6,0x1
    80004ea0:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004ea4:	6b85                	lui	s7,0x1
    80004ea6:	c00b8b9b          	addiw	s7,s7,-1024
    80004eaa:	a861                	j	80004f42 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004eac:	6908                	ld	a0,16(a0)
    80004eae:	00000097          	auipc	ra,0x0
    80004eb2:	22e080e7          	jalr	558(ra) # 800050dc <pipewrite>
    80004eb6:	8a2a                	mv	s4,a0
    80004eb8:	a045                	j	80004f58 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004eba:	02451783          	lh	a5,36(a0)
    80004ebe:	03079693          	slli	a3,a5,0x30
    80004ec2:	92c1                	srli	a3,a3,0x30
    80004ec4:	4725                	li	a4,9
    80004ec6:	0cd76263          	bltu	a4,a3,80004f8a <filewrite+0x12c>
    80004eca:	0792                	slli	a5,a5,0x4
    80004ecc:	0001d717          	auipc	a4,0x1d
    80004ed0:	fac70713          	addi	a4,a4,-84 # 80021e78 <devsw>
    80004ed4:	97ba                	add	a5,a5,a4
    80004ed6:	679c                	ld	a5,8(a5)
    80004ed8:	cbdd                	beqz	a5,80004f8e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004eda:	4505                	li	a0,1
    80004edc:	9782                	jalr	a5
    80004ede:	8a2a                	mv	s4,a0
    80004ee0:	a8a5                	j	80004f58 <filewrite+0xfa>
    80004ee2:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004ee6:	00000097          	auipc	ra,0x0
    80004eea:	8b0080e7          	jalr	-1872(ra) # 80004796 <begin_op>
      ilock(f->ip);
    80004eee:	01893503          	ld	a0,24(s2)
    80004ef2:	fffff097          	auipc	ra,0xfffff
    80004ef6:	ee2080e7          	jalr	-286(ra) # 80003dd4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004efa:	8762                	mv	a4,s8
    80004efc:	02092683          	lw	a3,32(s2)
    80004f00:	01598633          	add	a2,s3,s5
    80004f04:	4585                	li	a1,1
    80004f06:	01893503          	ld	a0,24(s2)
    80004f0a:	fffff097          	auipc	ra,0xfffff
    80004f0e:	276080e7          	jalr	630(ra) # 80004180 <writei>
    80004f12:	84aa                	mv	s1,a0
    80004f14:	00a05763          	blez	a0,80004f22 <filewrite+0xc4>
        f->off += r;
    80004f18:	02092783          	lw	a5,32(s2)
    80004f1c:	9fa9                	addw	a5,a5,a0
    80004f1e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004f22:	01893503          	ld	a0,24(s2)
    80004f26:	fffff097          	auipc	ra,0xfffff
    80004f2a:	f70080e7          	jalr	-144(ra) # 80003e96 <iunlock>
      end_op();
    80004f2e:	00000097          	auipc	ra,0x0
    80004f32:	8e8080e7          	jalr	-1816(ra) # 80004816 <end_op>

      if(r != n1){
    80004f36:	009c1f63          	bne	s8,s1,80004f54 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004f3a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004f3e:	0149db63          	bge	s3,s4,80004f54 <filewrite+0xf6>
      int n1 = n - i;
    80004f42:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004f46:	84be                	mv	s1,a5
    80004f48:	2781                	sext.w	a5,a5
    80004f4a:	f8fb5ce3          	bge	s6,a5,80004ee2 <filewrite+0x84>
    80004f4e:	84de                	mv	s1,s7
    80004f50:	bf49                	j	80004ee2 <filewrite+0x84>
    int i = 0;
    80004f52:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004f54:	013a1f63          	bne	s4,s3,80004f72 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004f58:	8552                	mv	a0,s4
    80004f5a:	60a6                	ld	ra,72(sp)
    80004f5c:	6406                	ld	s0,64(sp)
    80004f5e:	74e2                	ld	s1,56(sp)
    80004f60:	7942                	ld	s2,48(sp)
    80004f62:	79a2                	ld	s3,40(sp)
    80004f64:	7a02                	ld	s4,32(sp)
    80004f66:	6ae2                	ld	s5,24(sp)
    80004f68:	6b42                	ld	s6,16(sp)
    80004f6a:	6ba2                	ld	s7,8(sp)
    80004f6c:	6c02                	ld	s8,0(sp)
    80004f6e:	6161                	addi	sp,sp,80
    80004f70:	8082                	ret
    ret = (i == n ? n : -1);
    80004f72:	5a7d                	li	s4,-1
    80004f74:	b7d5                	j	80004f58 <filewrite+0xfa>
    panic("filewrite");
    80004f76:	00004517          	auipc	a0,0x4
    80004f7a:	89a50513          	addi	a0,a0,-1894 # 80008810 <syscalls+0x298>
    80004f7e:	ffffb097          	auipc	ra,0xffffb
    80004f82:	5c6080e7          	jalr	1478(ra) # 80000544 <panic>
    return -1;
    80004f86:	5a7d                	li	s4,-1
    80004f88:	bfc1                	j	80004f58 <filewrite+0xfa>
      return -1;
    80004f8a:	5a7d                	li	s4,-1
    80004f8c:	b7f1                	j	80004f58 <filewrite+0xfa>
    80004f8e:	5a7d                	li	s4,-1
    80004f90:	b7e1                	j	80004f58 <filewrite+0xfa>

0000000080004f92 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004f92:	7179                	addi	sp,sp,-48
    80004f94:	f406                	sd	ra,40(sp)
    80004f96:	f022                	sd	s0,32(sp)
    80004f98:	ec26                	sd	s1,24(sp)
    80004f9a:	e84a                	sd	s2,16(sp)
    80004f9c:	e44e                	sd	s3,8(sp)
    80004f9e:	e052                	sd	s4,0(sp)
    80004fa0:	1800                	addi	s0,sp,48
    80004fa2:	84aa                	mv	s1,a0
    80004fa4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004fa6:	0005b023          	sd	zero,0(a1)
    80004faa:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004fae:	00000097          	auipc	ra,0x0
    80004fb2:	bf8080e7          	jalr	-1032(ra) # 80004ba6 <filealloc>
    80004fb6:	e088                	sd	a0,0(s1)
    80004fb8:	c551                	beqz	a0,80005044 <pipealloc+0xb2>
    80004fba:	00000097          	auipc	ra,0x0
    80004fbe:	bec080e7          	jalr	-1044(ra) # 80004ba6 <filealloc>
    80004fc2:	00aa3023          	sd	a0,0(s4)
    80004fc6:	c92d                	beqz	a0,80005038 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004fc8:	ffffc097          	auipc	ra,0xffffc
    80004fcc:	b32080e7          	jalr	-1230(ra) # 80000afa <kalloc>
    80004fd0:	892a                	mv	s2,a0
    80004fd2:	c125                	beqz	a0,80005032 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004fd4:	4985                	li	s3,1
    80004fd6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004fda:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004fde:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004fe2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004fe6:	00003597          	auipc	a1,0x3
    80004fea:	4a258593          	addi	a1,a1,1186 # 80008488 <states.1800+0x1c0>
    80004fee:	ffffc097          	auipc	ra,0xffffc
    80004ff2:	b6c080e7          	jalr	-1172(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    80004ff6:	609c                	ld	a5,0(s1)
    80004ff8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004ffc:	609c                	ld	a5,0(s1)
    80004ffe:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005002:	609c                	ld	a5,0(s1)
    80005004:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005008:	609c                	ld	a5,0(s1)
    8000500a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000500e:	000a3783          	ld	a5,0(s4)
    80005012:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005016:	000a3783          	ld	a5,0(s4)
    8000501a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000501e:	000a3783          	ld	a5,0(s4)
    80005022:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005026:	000a3783          	ld	a5,0(s4)
    8000502a:	0127b823          	sd	s2,16(a5)
  return 0;
    8000502e:	4501                	li	a0,0
    80005030:	a025                	j	80005058 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005032:	6088                	ld	a0,0(s1)
    80005034:	e501                	bnez	a0,8000503c <pipealloc+0xaa>
    80005036:	a039                	j	80005044 <pipealloc+0xb2>
    80005038:	6088                	ld	a0,0(s1)
    8000503a:	c51d                	beqz	a0,80005068 <pipealloc+0xd6>
    fileclose(*f0);
    8000503c:	00000097          	auipc	ra,0x0
    80005040:	c26080e7          	jalr	-986(ra) # 80004c62 <fileclose>
  if(*f1)
    80005044:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005048:	557d                	li	a0,-1
  if(*f1)
    8000504a:	c799                	beqz	a5,80005058 <pipealloc+0xc6>
    fileclose(*f1);
    8000504c:	853e                	mv	a0,a5
    8000504e:	00000097          	auipc	ra,0x0
    80005052:	c14080e7          	jalr	-1004(ra) # 80004c62 <fileclose>
  return -1;
    80005056:	557d                	li	a0,-1
}
    80005058:	70a2                	ld	ra,40(sp)
    8000505a:	7402                	ld	s0,32(sp)
    8000505c:	64e2                	ld	s1,24(sp)
    8000505e:	6942                	ld	s2,16(sp)
    80005060:	69a2                	ld	s3,8(sp)
    80005062:	6a02                	ld	s4,0(sp)
    80005064:	6145                	addi	sp,sp,48
    80005066:	8082                	ret
  return -1;
    80005068:	557d                	li	a0,-1
    8000506a:	b7fd                	j	80005058 <pipealloc+0xc6>

000000008000506c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000506c:	1101                	addi	sp,sp,-32
    8000506e:	ec06                	sd	ra,24(sp)
    80005070:	e822                	sd	s0,16(sp)
    80005072:	e426                	sd	s1,8(sp)
    80005074:	e04a                	sd	s2,0(sp)
    80005076:	1000                	addi	s0,sp,32
    80005078:	84aa                	mv	s1,a0
    8000507a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000507c:	ffffc097          	auipc	ra,0xffffc
    80005080:	b6e080e7          	jalr	-1170(ra) # 80000bea <acquire>
  if(writable){
    80005084:	02090d63          	beqz	s2,800050be <pipeclose+0x52>
    pi->writeopen = 0;
    80005088:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000508c:	21848513          	addi	a0,s1,536
    80005090:	ffffd097          	auipc	ra,0xffffd
    80005094:	4a6080e7          	jalr	1190(ra) # 80002536 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005098:	2204b783          	ld	a5,544(s1)
    8000509c:	eb95                	bnez	a5,800050d0 <pipeclose+0x64>
    release(&pi->lock);
    8000509e:	8526                	mv	a0,s1
    800050a0:	ffffc097          	auipc	ra,0xffffc
    800050a4:	bfe080e7          	jalr	-1026(ra) # 80000c9e <release>
    kfree((char*)pi);
    800050a8:	8526                	mv	a0,s1
    800050aa:	ffffc097          	auipc	ra,0xffffc
    800050ae:	954080e7          	jalr	-1708(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    800050b2:	60e2                	ld	ra,24(sp)
    800050b4:	6442                	ld	s0,16(sp)
    800050b6:	64a2                	ld	s1,8(sp)
    800050b8:	6902                	ld	s2,0(sp)
    800050ba:	6105                	addi	sp,sp,32
    800050bc:	8082                	ret
    pi->readopen = 0;
    800050be:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800050c2:	21c48513          	addi	a0,s1,540
    800050c6:	ffffd097          	auipc	ra,0xffffd
    800050ca:	470080e7          	jalr	1136(ra) # 80002536 <wakeup>
    800050ce:	b7e9                	j	80005098 <pipeclose+0x2c>
    release(&pi->lock);
    800050d0:	8526                	mv	a0,s1
    800050d2:	ffffc097          	auipc	ra,0xffffc
    800050d6:	bcc080e7          	jalr	-1076(ra) # 80000c9e <release>
}
    800050da:	bfe1                	j	800050b2 <pipeclose+0x46>

00000000800050dc <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800050dc:	7159                	addi	sp,sp,-112
    800050de:	f486                	sd	ra,104(sp)
    800050e0:	f0a2                	sd	s0,96(sp)
    800050e2:	eca6                	sd	s1,88(sp)
    800050e4:	e8ca                	sd	s2,80(sp)
    800050e6:	e4ce                	sd	s3,72(sp)
    800050e8:	e0d2                	sd	s4,64(sp)
    800050ea:	fc56                	sd	s5,56(sp)
    800050ec:	f85a                	sd	s6,48(sp)
    800050ee:	f45e                	sd	s7,40(sp)
    800050f0:	f062                	sd	s8,32(sp)
    800050f2:	ec66                	sd	s9,24(sp)
    800050f4:	1880                	addi	s0,sp,112
    800050f6:	84aa                	mv	s1,a0
    800050f8:	8aae                	mv	s5,a1
    800050fa:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800050fc:	ffffd097          	auipc	ra,0xffffd
    80005100:	8ca080e7          	jalr	-1846(ra) # 800019c6 <myproc>
    80005104:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005106:	8526                	mv	a0,s1
    80005108:	ffffc097          	auipc	ra,0xffffc
    8000510c:	ae2080e7          	jalr	-1310(ra) # 80000bea <acquire>
  while(i < n){
    80005110:	0d405463          	blez	s4,800051d8 <pipewrite+0xfc>
    80005114:	8ba6                	mv	s7,s1
  int i = 0;
    80005116:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005118:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000511a:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000511e:	21c48c13          	addi	s8,s1,540
    80005122:	a08d                	j	80005184 <pipewrite+0xa8>
      release(&pi->lock);
    80005124:	8526                	mv	a0,s1
    80005126:	ffffc097          	auipc	ra,0xffffc
    8000512a:	b78080e7          	jalr	-1160(ra) # 80000c9e <release>
      return -1;
    8000512e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005130:	854a                	mv	a0,s2
    80005132:	70a6                	ld	ra,104(sp)
    80005134:	7406                	ld	s0,96(sp)
    80005136:	64e6                	ld	s1,88(sp)
    80005138:	6946                	ld	s2,80(sp)
    8000513a:	69a6                	ld	s3,72(sp)
    8000513c:	6a06                	ld	s4,64(sp)
    8000513e:	7ae2                	ld	s5,56(sp)
    80005140:	7b42                	ld	s6,48(sp)
    80005142:	7ba2                	ld	s7,40(sp)
    80005144:	7c02                	ld	s8,32(sp)
    80005146:	6ce2                	ld	s9,24(sp)
    80005148:	6165                	addi	sp,sp,112
    8000514a:	8082                	ret
      wakeup(&pi->nread);
    8000514c:	8566                	mv	a0,s9
    8000514e:	ffffd097          	auipc	ra,0xffffd
    80005152:	3e8080e7          	jalr	1000(ra) # 80002536 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005156:	85de                	mv	a1,s7
    80005158:	8562                	mv	a0,s8
    8000515a:	ffffd097          	auipc	ra,0xffffd
    8000515e:	22c080e7          	jalr	556(ra) # 80002386 <sleep>
    80005162:	a839                	j	80005180 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005164:	21c4a783          	lw	a5,540(s1)
    80005168:	0017871b          	addiw	a4,a5,1
    8000516c:	20e4ae23          	sw	a4,540(s1)
    80005170:	1ff7f793          	andi	a5,a5,511
    80005174:	97a6                	add	a5,a5,s1
    80005176:	f9f44703          	lbu	a4,-97(s0)
    8000517a:	00e78c23          	sb	a4,24(a5)
      i++;
    8000517e:	2905                	addiw	s2,s2,1
  while(i < n){
    80005180:	05495063          	bge	s2,s4,800051c0 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80005184:	2204a783          	lw	a5,544(s1)
    80005188:	dfd1                	beqz	a5,80005124 <pipewrite+0x48>
    8000518a:	854e                	mv	a0,s3
    8000518c:	ffffd097          	auipc	ra,0xffffd
    80005190:	5fa080e7          	jalr	1530(ra) # 80002786 <killed>
    80005194:	f941                	bnez	a0,80005124 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005196:	2184a783          	lw	a5,536(s1)
    8000519a:	21c4a703          	lw	a4,540(s1)
    8000519e:	2007879b          	addiw	a5,a5,512
    800051a2:	faf705e3          	beq	a4,a5,8000514c <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800051a6:	4685                	li	a3,1
    800051a8:	01590633          	add	a2,s2,s5
    800051ac:	f9f40593          	addi	a1,s0,-97
    800051b0:	0509b503          	ld	a0,80(s3)
    800051b4:	ffffc097          	auipc	ra,0xffffc
    800051b8:	55c080e7          	jalr	1372(ra) # 80001710 <copyin>
    800051bc:	fb6514e3          	bne	a0,s6,80005164 <pipewrite+0x88>
  wakeup(&pi->nread);
    800051c0:	21848513          	addi	a0,s1,536
    800051c4:	ffffd097          	auipc	ra,0xffffd
    800051c8:	372080e7          	jalr	882(ra) # 80002536 <wakeup>
  release(&pi->lock);
    800051cc:	8526                	mv	a0,s1
    800051ce:	ffffc097          	auipc	ra,0xffffc
    800051d2:	ad0080e7          	jalr	-1328(ra) # 80000c9e <release>
  return i;
    800051d6:	bfa9                	j	80005130 <pipewrite+0x54>
  int i = 0;
    800051d8:	4901                	li	s2,0
    800051da:	b7dd                	j	800051c0 <pipewrite+0xe4>

00000000800051dc <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800051dc:	715d                	addi	sp,sp,-80
    800051de:	e486                	sd	ra,72(sp)
    800051e0:	e0a2                	sd	s0,64(sp)
    800051e2:	fc26                	sd	s1,56(sp)
    800051e4:	f84a                	sd	s2,48(sp)
    800051e6:	f44e                	sd	s3,40(sp)
    800051e8:	f052                	sd	s4,32(sp)
    800051ea:	ec56                	sd	s5,24(sp)
    800051ec:	e85a                	sd	s6,16(sp)
    800051ee:	0880                	addi	s0,sp,80
    800051f0:	84aa                	mv	s1,a0
    800051f2:	892e                	mv	s2,a1
    800051f4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800051f6:	ffffc097          	auipc	ra,0xffffc
    800051fa:	7d0080e7          	jalr	2000(ra) # 800019c6 <myproc>
    800051fe:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005200:	8b26                	mv	s6,s1
    80005202:	8526                	mv	a0,s1
    80005204:	ffffc097          	auipc	ra,0xffffc
    80005208:	9e6080e7          	jalr	-1562(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000520c:	2184a703          	lw	a4,536(s1)
    80005210:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005214:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005218:	02f71763          	bne	a4,a5,80005246 <piperead+0x6a>
    8000521c:	2244a783          	lw	a5,548(s1)
    80005220:	c39d                	beqz	a5,80005246 <piperead+0x6a>
    if(killed(pr)){
    80005222:	8552                	mv	a0,s4
    80005224:	ffffd097          	auipc	ra,0xffffd
    80005228:	562080e7          	jalr	1378(ra) # 80002786 <killed>
    8000522c:	e941                	bnez	a0,800052bc <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000522e:	85da                	mv	a1,s6
    80005230:	854e                	mv	a0,s3
    80005232:	ffffd097          	auipc	ra,0xffffd
    80005236:	154080e7          	jalr	340(ra) # 80002386 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000523a:	2184a703          	lw	a4,536(s1)
    8000523e:	21c4a783          	lw	a5,540(s1)
    80005242:	fcf70de3          	beq	a4,a5,8000521c <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005246:	09505263          	blez	s5,800052ca <piperead+0xee>
    8000524a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000524c:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    8000524e:	2184a783          	lw	a5,536(s1)
    80005252:	21c4a703          	lw	a4,540(s1)
    80005256:	02f70d63          	beq	a4,a5,80005290 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000525a:	0017871b          	addiw	a4,a5,1
    8000525e:	20e4ac23          	sw	a4,536(s1)
    80005262:	1ff7f793          	andi	a5,a5,511
    80005266:	97a6                	add	a5,a5,s1
    80005268:	0187c783          	lbu	a5,24(a5)
    8000526c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005270:	4685                	li	a3,1
    80005272:	fbf40613          	addi	a2,s0,-65
    80005276:	85ca                	mv	a1,s2
    80005278:	050a3503          	ld	a0,80(s4)
    8000527c:	ffffc097          	auipc	ra,0xffffc
    80005280:	408080e7          	jalr	1032(ra) # 80001684 <copyout>
    80005284:	01650663          	beq	a0,s6,80005290 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005288:	2985                	addiw	s3,s3,1
    8000528a:	0905                	addi	s2,s2,1
    8000528c:	fd3a91e3          	bne	s5,s3,8000524e <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005290:	21c48513          	addi	a0,s1,540
    80005294:	ffffd097          	auipc	ra,0xffffd
    80005298:	2a2080e7          	jalr	674(ra) # 80002536 <wakeup>
  release(&pi->lock);
    8000529c:	8526                	mv	a0,s1
    8000529e:	ffffc097          	auipc	ra,0xffffc
    800052a2:	a00080e7          	jalr	-1536(ra) # 80000c9e <release>
  return i;
}
    800052a6:	854e                	mv	a0,s3
    800052a8:	60a6                	ld	ra,72(sp)
    800052aa:	6406                	ld	s0,64(sp)
    800052ac:	74e2                	ld	s1,56(sp)
    800052ae:	7942                	ld	s2,48(sp)
    800052b0:	79a2                	ld	s3,40(sp)
    800052b2:	7a02                	ld	s4,32(sp)
    800052b4:	6ae2                	ld	s5,24(sp)
    800052b6:	6b42                	ld	s6,16(sp)
    800052b8:	6161                	addi	sp,sp,80
    800052ba:	8082                	ret
      release(&pi->lock);
    800052bc:	8526                	mv	a0,s1
    800052be:	ffffc097          	auipc	ra,0xffffc
    800052c2:	9e0080e7          	jalr	-1568(ra) # 80000c9e <release>
      return -1;
    800052c6:	59fd                	li	s3,-1
    800052c8:	bff9                	j	800052a6 <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052ca:	4981                	li	s3,0
    800052cc:	b7d1                	j	80005290 <piperead+0xb4>

00000000800052ce <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    800052ce:	1141                	addi	sp,sp,-16
    800052d0:	e422                	sd	s0,8(sp)
    800052d2:	0800                	addi	s0,sp,16
    800052d4:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800052d6:	8905                	andi	a0,a0,1
    800052d8:	c111                	beqz	a0,800052dc <flags2perm+0xe>
      perm = PTE_X;
    800052da:	4521                	li	a0,8
    if(flags & 0x2)
    800052dc:	8b89                	andi	a5,a5,2
    800052de:	c399                	beqz	a5,800052e4 <flags2perm+0x16>
      perm |= PTE_W;
    800052e0:	00456513          	ori	a0,a0,4
    return perm;
}
    800052e4:	6422                	ld	s0,8(sp)
    800052e6:	0141                	addi	sp,sp,16
    800052e8:	8082                	ret

00000000800052ea <exec>:

int
exec(char *path, char **argv)
{
    800052ea:	df010113          	addi	sp,sp,-528
    800052ee:	20113423          	sd	ra,520(sp)
    800052f2:	20813023          	sd	s0,512(sp)
    800052f6:	ffa6                	sd	s1,504(sp)
    800052f8:	fbca                	sd	s2,496(sp)
    800052fa:	f7ce                	sd	s3,488(sp)
    800052fc:	f3d2                	sd	s4,480(sp)
    800052fe:	efd6                	sd	s5,472(sp)
    80005300:	ebda                	sd	s6,464(sp)
    80005302:	e7de                	sd	s7,456(sp)
    80005304:	e3e2                	sd	s8,448(sp)
    80005306:	ff66                	sd	s9,440(sp)
    80005308:	fb6a                	sd	s10,432(sp)
    8000530a:	f76e                	sd	s11,424(sp)
    8000530c:	0c00                	addi	s0,sp,528
    8000530e:	84aa                	mv	s1,a0
    80005310:	dea43c23          	sd	a0,-520(s0)
    80005314:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005318:	ffffc097          	auipc	ra,0xffffc
    8000531c:	6ae080e7          	jalr	1710(ra) # 800019c6 <myproc>
    80005320:	892a                	mv	s2,a0

  begin_op();
    80005322:	fffff097          	auipc	ra,0xfffff
    80005326:	474080e7          	jalr	1140(ra) # 80004796 <begin_op>

  if((ip = namei(path)) == 0){
    8000532a:	8526                	mv	a0,s1
    8000532c:	fffff097          	auipc	ra,0xfffff
    80005330:	24e080e7          	jalr	590(ra) # 8000457a <namei>
    80005334:	c92d                	beqz	a0,800053a6 <exec+0xbc>
    80005336:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005338:	fffff097          	auipc	ra,0xfffff
    8000533c:	a9c080e7          	jalr	-1380(ra) # 80003dd4 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005340:	04000713          	li	a4,64
    80005344:	4681                	li	a3,0
    80005346:	e5040613          	addi	a2,s0,-432
    8000534a:	4581                	li	a1,0
    8000534c:	8526                	mv	a0,s1
    8000534e:	fffff097          	auipc	ra,0xfffff
    80005352:	d3a080e7          	jalr	-710(ra) # 80004088 <readi>
    80005356:	04000793          	li	a5,64
    8000535a:	00f51a63          	bne	a0,a5,8000536e <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    8000535e:	e5042703          	lw	a4,-432(s0)
    80005362:	464c47b7          	lui	a5,0x464c4
    80005366:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000536a:	04f70463          	beq	a4,a5,800053b2 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000536e:	8526                	mv	a0,s1
    80005370:	fffff097          	auipc	ra,0xfffff
    80005374:	cc6080e7          	jalr	-826(ra) # 80004036 <iunlockput>
    end_op();
    80005378:	fffff097          	auipc	ra,0xfffff
    8000537c:	49e080e7          	jalr	1182(ra) # 80004816 <end_op>
  }
  return -1;
    80005380:	557d                	li	a0,-1
}
    80005382:	20813083          	ld	ra,520(sp)
    80005386:	20013403          	ld	s0,512(sp)
    8000538a:	74fe                	ld	s1,504(sp)
    8000538c:	795e                	ld	s2,496(sp)
    8000538e:	79be                	ld	s3,488(sp)
    80005390:	7a1e                	ld	s4,480(sp)
    80005392:	6afe                	ld	s5,472(sp)
    80005394:	6b5e                	ld	s6,464(sp)
    80005396:	6bbe                	ld	s7,456(sp)
    80005398:	6c1e                	ld	s8,448(sp)
    8000539a:	7cfa                	ld	s9,440(sp)
    8000539c:	7d5a                	ld	s10,432(sp)
    8000539e:	7dba                	ld	s11,424(sp)
    800053a0:	21010113          	addi	sp,sp,528
    800053a4:	8082                	ret
    end_op();
    800053a6:	fffff097          	auipc	ra,0xfffff
    800053aa:	470080e7          	jalr	1136(ra) # 80004816 <end_op>
    return -1;
    800053ae:	557d                	li	a0,-1
    800053b0:	bfc9                	j	80005382 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800053b2:	854a                	mv	a0,s2
    800053b4:	ffffc097          	auipc	ra,0xffffc
    800053b8:	6d6080e7          	jalr	1750(ra) # 80001a8a <proc_pagetable>
    800053bc:	8baa                	mv	s7,a0
    800053be:	d945                	beqz	a0,8000536e <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053c0:	e7042983          	lw	s3,-400(s0)
    800053c4:	e8845783          	lhu	a5,-376(s0)
    800053c8:	c7ad                	beqz	a5,80005432 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800053ca:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053cc:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    800053ce:	6c85                	lui	s9,0x1
    800053d0:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800053d4:	def43823          	sd	a5,-528(s0)
    800053d8:	ac0d                	j	8000560a <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800053da:	00003517          	auipc	a0,0x3
    800053de:	44650513          	addi	a0,a0,1094 # 80008820 <syscalls+0x2a8>
    800053e2:	ffffb097          	auipc	ra,0xffffb
    800053e6:	162080e7          	jalr	354(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800053ea:	8756                	mv	a4,s5
    800053ec:	012d86bb          	addw	a3,s11,s2
    800053f0:	4581                	li	a1,0
    800053f2:	8526                	mv	a0,s1
    800053f4:	fffff097          	auipc	ra,0xfffff
    800053f8:	c94080e7          	jalr	-876(ra) # 80004088 <readi>
    800053fc:	2501                	sext.w	a0,a0
    800053fe:	1aaa9a63          	bne	s5,a0,800055b2 <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    80005402:	6785                	lui	a5,0x1
    80005404:	0127893b          	addw	s2,a5,s2
    80005408:	77fd                	lui	a5,0xfffff
    8000540a:	01478a3b          	addw	s4,a5,s4
    8000540e:	1f897563          	bgeu	s2,s8,800055f8 <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    80005412:	02091593          	slli	a1,s2,0x20
    80005416:	9181                	srli	a1,a1,0x20
    80005418:	95ea                	add	a1,a1,s10
    8000541a:	855e                	mv	a0,s7
    8000541c:	ffffc097          	auipc	ra,0xffffc
    80005420:	c5c080e7          	jalr	-932(ra) # 80001078 <walkaddr>
    80005424:	862a                	mv	a2,a0
    if(pa == 0)
    80005426:	d955                	beqz	a0,800053da <exec+0xf0>
      n = PGSIZE;
    80005428:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    8000542a:	fd9a70e3          	bgeu	s4,s9,800053ea <exec+0x100>
      n = sz - i;
    8000542e:	8ad2                	mv	s5,s4
    80005430:	bf6d                	j	800053ea <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005432:	4a01                	li	s4,0
  iunlockput(ip);
    80005434:	8526                	mv	a0,s1
    80005436:	fffff097          	auipc	ra,0xfffff
    8000543a:	c00080e7          	jalr	-1024(ra) # 80004036 <iunlockput>
  end_op();
    8000543e:	fffff097          	auipc	ra,0xfffff
    80005442:	3d8080e7          	jalr	984(ra) # 80004816 <end_op>
  p = myproc();
    80005446:	ffffc097          	auipc	ra,0xffffc
    8000544a:	580080e7          	jalr	1408(ra) # 800019c6 <myproc>
    8000544e:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005450:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005454:	6785                	lui	a5,0x1
    80005456:	17fd                	addi	a5,a5,-1
    80005458:	9a3e                	add	s4,s4,a5
    8000545a:	757d                	lui	a0,0xfffff
    8000545c:	00aa77b3          	and	a5,s4,a0
    80005460:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005464:	4691                	li	a3,4
    80005466:	6609                	lui	a2,0x2
    80005468:	963e                	add	a2,a2,a5
    8000546a:	85be                	mv	a1,a5
    8000546c:	855e                	mv	a0,s7
    8000546e:	ffffc097          	auipc	ra,0xffffc
    80005472:	fbe080e7          	jalr	-66(ra) # 8000142c <uvmalloc>
    80005476:	8b2a                	mv	s6,a0
  ip = 0;
    80005478:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000547a:	12050c63          	beqz	a0,800055b2 <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000547e:	75f9                	lui	a1,0xffffe
    80005480:	95aa                	add	a1,a1,a0
    80005482:	855e                	mv	a0,s7
    80005484:	ffffc097          	auipc	ra,0xffffc
    80005488:	1ce080e7          	jalr	462(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    8000548c:	7c7d                	lui	s8,0xfffff
    8000548e:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005490:	e0043783          	ld	a5,-512(s0)
    80005494:	6388                	ld	a0,0(a5)
    80005496:	c535                	beqz	a0,80005502 <exec+0x218>
    80005498:	e9040993          	addi	s3,s0,-368
    8000549c:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800054a0:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800054a2:	ffffc097          	auipc	ra,0xffffc
    800054a6:	9c8080e7          	jalr	-1592(ra) # 80000e6a <strlen>
    800054aa:	2505                	addiw	a0,a0,1
    800054ac:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800054b0:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800054b4:	13896663          	bltu	s2,s8,800055e0 <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800054b8:	e0043d83          	ld	s11,-512(s0)
    800054bc:	000dba03          	ld	s4,0(s11)
    800054c0:	8552                	mv	a0,s4
    800054c2:	ffffc097          	auipc	ra,0xffffc
    800054c6:	9a8080e7          	jalr	-1624(ra) # 80000e6a <strlen>
    800054ca:	0015069b          	addiw	a3,a0,1
    800054ce:	8652                	mv	a2,s4
    800054d0:	85ca                	mv	a1,s2
    800054d2:	855e                	mv	a0,s7
    800054d4:	ffffc097          	auipc	ra,0xffffc
    800054d8:	1b0080e7          	jalr	432(ra) # 80001684 <copyout>
    800054dc:	10054663          	bltz	a0,800055e8 <exec+0x2fe>
    ustack[argc] = sp;
    800054e0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800054e4:	0485                	addi	s1,s1,1
    800054e6:	008d8793          	addi	a5,s11,8
    800054ea:	e0f43023          	sd	a5,-512(s0)
    800054ee:	008db503          	ld	a0,8(s11)
    800054f2:	c911                	beqz	a0,80005506 <exec+0x21c>
    if(argc >= MAXARG)
    800054f4:	09a1                	addi	s3,s3,8
    800054f6:	fb3c96e3          	bne	s9,s3,800054a2 <exec+0x1b8>
  sz = sz1;
    800054fa:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800054fe:	4481                	li	s1,0
    80005500:	a84d                	j	800055b2 <exec+0x2c8>
  sp = sz;
    80005502:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005504:	4481                	li	s1,0
  ustack[argc] = 0;
    80005506:	00349793          	slli	a5,s1,0x3
    8000550a:	f9040713          	addi	a4,s0,-112
    8000550e:	97ba                	add	a5,a5,a4
    80005510:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005514:	00148693          	addi	a3,s1,1
    80005518:	068e                	slli	a3,a3,0x3
    8000551a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000551e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005522:	01897663          	bgeu	s2,s8,8000552e <exec+0x244>
  sz = sz1;
    80005526:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000552a:	4481                	li	s1,0
    8000552c:	a059                	j	800055b2 <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000552e:	e9040613          	addi	a2,s0,-368
    80005532:	85ca                	mv	a1,s2
    80005534:	855e                	mv	a0,s7
    80005536:	ffffc097          	auipc	ra,0xffffc
    8000553a:	14e080e7          	jalr	334(ra) # 80001684 <copyout>
    8000553e:	0a054963          	bltz	a0,800055f0 <exec+0x306>
  p->trapframe->a1 = sp;
    80005542:	058ab783          	ld	a5,88(s5)
    80005546:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000554a:	df843783          	ld	a5,-520(s0)
    8000554e:	0007c703          	lbu	a4,0(a5)
    80005552:	cf11                	beqz	a4,8000556e <exec+0x284>
    80005554:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005556:	02f00693          	li	a3,47
    8000555a:	a039                	j	80005568 <exec+0x27e>
      last = s+1;
    8000555c:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005560:	0785                	addi	a5,a5,1
    80005562:	fff7c703          	lbu	a4,-1(a5)
    80005566:	c701                	beqz	a4,8000556e <exec+0x284>
    if(*s == '/')
    80005568:	fed71ce3          	bne	a4,a3,80005560 <exec+0x276>
    8000556c:	bfc5                	j	8000555c <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    8000556e:	4641                	li	a2,16
    80005570:	df843583          	ld	a1,-520(s0)
    80005574:	158a8513          	addi	a0,s5,344
    80005578:	ffffc097          	auipc	ra,0xffffc
    8000557c:	8c0080e7          	jalr	-1856(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    80005580:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005584:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005588:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000558c:	058ab783          	ld	a5,88(s5)
    80005590:	e6843703          	ld	a4,-408(s0)
    80005594:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005596:	058ab783          	ld	a5,88(s5)
    8000559a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000559e:	85ea                	mv	a1,s10
    800055a0:	ffffc097          	auipc	ra,0xffffc
    800055a4:	586080e7          	jalr	1414(ra) # 80001b26 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800055a8:	0004851b          	sext.w	a0,s1
    800055ac:	bbd9                	j	80005382 <exec+0x98>
    800055ae:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    800055b2:	e0843583          	ld	a1,-504(s0)
    800055b6:	855e                	mv	a0,s7
    800055b8:	ffffc097          	auipc	ra,0xffffc
    800055bc:	56e080e7          	jalr	1390(ra) # 80001b26 <proc_freepagetable>
  if(ip){
    800055c0:	da0497e3          	bnez	s1,8000536e <exec+0x84>
  return -1;
    800055c4:	557d                	li	a0,-1
    800055c6:	bb75                	j	80005382 <exec+0x98>
    800055c8:	e1443423          	sd	s4,-504(s0)
    800055cc:	b7dd                	j	800055b2 <exec+0x2c8>
    800055ce:	e1443423          	sd	s4,-504(s0)
    800055d2:	b7c5                	j	800055b2 <exec+0x2c8>
    800055d4:	e1443423          	sd	s4,-504(s0)
    800055d8:	bfe9                	j	800055b2 <exec+0x2c8>
    800055da:	e1443423          	sd	s4,-504(s0)
    800055de:	bfd1                	j	800055b2 <exec+0x2c8>
  sz = sz1;
    800055e0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055e4:	4481                	li	s1,0
    800055e6:	b7f1                	j	800055b2 <exec+0x2c8>
  sz = sz1;
    800055e8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055ec:	4481                	li	s1,0
    800055ee:	b7d1                	j	800055b2 <exec+0x2c8>
  sz = sz1;
    800055f0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055f4:	4481                	li	s1,0
    800055f6:	bf75                	j	800055b2 <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800055f8:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800055fc:	2b05                	addiw	s6,s6,1
    800055fe:	0389899b          	addiw	s3,s3,56
    80005602:	e8845783          	lhu	a5,-376(s0)
    80005606:	e2fb57e3          	bge	s6,a5,80005434 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000560a:	2981                	sext.w	s3,s3
    8000560c:	03800713          	li	a4,56
    80005610:	86ce                	mv	a3,s3
    80005612:	e1840613          	addi	a2,s0,-488
    80005616:	4581                	li	a1,0
    80005618:	8526                	mv	a0,s1
    8000561a:	fffff097          	auipc	ra,0xfffff
    8000561e:	a6e080e7          	jalr	-1426(ra) # 80004088 <readi>
    80005622:	03800793          	li	a5,56
    80005626:	f8f514e3          	bne	a0,a5,800055ae <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    8000562a:	e1842783          	lw	a5,-488(s0)
    8000562e:	4705                	li	a4,1
    80005630:	fce796e3          	bne	a5,a4,800055fc <exec+0x312>
    if(ph.memsz < ph.filesz)
    80005634:	e4043903          	ld	s2,-448(s0)
    80005638:	e3843783          	ld	a5,-456(s0)
    8000563c:	f8f966e3          	bltu	s2,a5,800055c8 <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005640:	e2843783          	ld	a5,-472(s0)
    80005644:	993e                	add	s2,s2,a5
    80005646:	f8f964e3          	bltu	s2,a5,800055ce <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    8000564a:	df043703          	ld	a4,-528(s0)
    8000564e:	8ff9                	and	a5,a5,a4
    80005650:	f3d1                	bnez	a5,800055d4 <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005652:	e1c42503          	lw	a0,-484(s0)
    80005656:	00000097          	auipc	ra,0x0
    8000565a:	c78080e7          	jalr	-904(ra) # 800052ce <flags2perm>
    8000565e:	86aa                	mv	a3,a0
    80005660:	864a                	mv	a2,s2
    80005662:	85d2                	mv	a1,s4
    80005664:	855e                	mv	a0,s7
    80005666:	ffffc097          	auipc	ra,0xffffc
    8000566a:	dc6080e7          	jalr	-570(ra) # 8000142c <uvmalloc>
    8000566e:	e0a43423          	sd	a0,-504(s0)
    80005672:	d525                	beqz	a0,800055da <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005674:	e2843d03          	ld	s10,-472(s0)
    80005678:	e2042d83          	lw	s11,-480(s0)
    8000567c:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005680:	f60c0ce3          	beqz	s8,800055f8 <exec+0x30e>
    80005684:	8a62                	mv	s4,s8
    80005686:	4901                	li	s2,0
    80005688:	b369                	j	80005412 <exec+0x128>

000000008000568a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000568a:	7179                	addi	sp,sp,-48
    8000568c:	f406                	sd	ra,40(sp)
    8000568e:	f022                	sd	s0,32(sp)
    80005690:	ec26                	sd	s1,24(sp)
    80005692:	e84a                	sd	s2,16(sp)
    80005694:	1800                	addi	s0,sp,48
    80005696:	892e                	mv	s2,a1
    80005698:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000569a:	fdc40593          	addi	a1,s0,-36
    8000569e:	ffffe097          	auipc	ra,0xffffe
    800056a2:	8f4080e7          	jalr	-1804(ra) # 80002f92 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800056a6:	fdc42703          	lw	a4,-36(s0)
    800056aa:	47bd                	li	a5,15
    800056ac:	02e7eb63          	bltu	a5,a4,800056e2 <argfd+0x58>
    800056b0:	ffffc097          	auipc	ra,0xffffc
    800056b4:	316080e7          	jalr	790(ra) # 800019c6 <myproc>
    800056b8:	fdc42703          	lw	a4,-36(s0)
    800056bc:	01a70793          	addi	a5,a4,26
    800056c0:	078e                	slli	a5,a5,0x3
    800056c2:	953e                	add	a0,a0,a5
    800056c4:	611c                	ld	a5,0(a0)
    800056c6:	c385                	beqz	a5,800056e6 <argfd+0x5c>
    return -1;
  if(pfd)
    800056c8:	00090463          	beqz	s2,800056d0 <argfd+0x46>
    *pfd = fd;
    800056cc:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800056d0:	4501                	li	a0,0
  if(pf)
    800056d2:	c091                	beqz	s1,800056d6 <argfd+0x4c>
    *pf = f;
    800056d4:	e09c                	sd	a5,0(s1)
}
    800056d6:	70a2                	ld	ra,40(sp)
    800056d8:	7402                	ld	s0,32(sp)
    800056da:	64e2                	ld	s1,24(sp)
    800056dc:	6942                	ld	s2,16(sp)
    800056de:	6145                	addi	sp,sp,48
    800056e0:	8082                	ret
    return -1;
    800056e2:	557d                	li	a0,-1
    800056e4:	bfcd                	j	800056d6 <argfd+0x4c>
    800056e6:	557d                	li	a0,-1
    800056e8:	b7fd                	j	800056d6 <argfd+0x4c>

00000000800056ea <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800056ea:	1101                	addi	sp,sp,-32
    800056ec:	ec06                	sd	ra,24(sp)
    800056ee:	e822                	sd	s0,16(sp)
    800056f0:	e426                	sd	s1,8(sp)
    800056f2:	1000                	addi	s0,sp,32
    800056f4:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800056f6:	ffffc097          	auipc	ra,0xffffc
    800056fa:	2d0080e7          	jalr	720(ra) # 800019c6 <myproc>
    800056fe:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005700:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffdc0c0>
    80005704:	4501                	li	a0,0
    80005706:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005708:	6398                	ld	a4,0(a5)
    8000570a:	cb19                	beqz	a4,80005720 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000570c:	2505                	addiw	a0,a0,1
    8000570e:	07a1                	addi	a5,a5,8
    80005710:	fed51ce3          	bne	a0,a3,80005708 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005714:	557d                	li	a0,-1
}
    80005716:	60e2                	ld	ra,24(sp)
    80005718:	6442                	ld	s0,16(sp)
    8000571a:	64a2                	ld	s1,8(sp)
    8000571c:	6105                	addi	sp,sp,32
    8000571e:	8082                	ret
      p->ofile[fd] = f;
    80005720:	01a50793          	addi	a5,a0,26
    80005724:	078e                	slli	a5,a5,0x3
    80005726:	963e                	add	a2,a2,a5
    80005728:	e204                	sd	s1,0(a2)
      return fd;
    8000572a:	b7f5                	j	80005716 <fdalloc+0x2c>

000000008000572c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000572c:	715d                	addi	sp,sp,-80
    8000572e:	e486                	sd	ra,72(sp)
    80005730:	e0a2                	sd	s0,64(sp)
    80005732:	fc26                	sd	s1,56(sp)
    80005734:	f84a                	sd	s2,48(sp)
    80005736:	f44e                	sd	s3,40(sp)
    80005738:	f052                	sd	s4,32(sp)
    8000573a:	ec56                	sd	s5,24(sp)
    8000573c:	e85a                	sd	s6,16(sp)
    8000573e:	0880                	addi	s0,sp,80
    80005740:	8b2e                	mv	s6,a1
    80005742:	89b2                	mv	s3,a2
    80005744:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005746:	fb040593          	addi	a1,s0,-80
    8000574a:	fffff097          	auipc	ra,0xfffff
    8000574e:	e4e080e7          	jalr	-434(ra) # 80004598 <nameiparent>
    80005752:	84aa                	mv	s1,a0
    80005754:	16050063          	beqz	a0,800058b4 <create+0x188>
    return 0;

  ilock(dp);
    80005758:	ffffe097          	auipc	ra,0xffffe
    8000575c:	67c080e7          	jalr	1660(ra) # 80003dd4 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005760:	4601                	li	a2,0
    80005762:	fb040593          	addi	a1,s0,-80
    80005766:	8526                	mv	a0,s1
    80005768:	fffff097          	auipc	ra,0xfffff
    8000576c:	b50080e7          	jalr	-1200(ra) # 800042b8 <dirlookup>
    80005770:	8aaa                	mv	s5,a0
    80005772:	c931                	beqz	a0,800057c6 <create+0x9a>
    iunlockput(dp);
    80005774:	8526                	mv	a0,s1
    80005776:	fffff097          	auipc	ra,0xfffff
    8000577a:	8c0080e7          	jalr	-1856(ra) # 80004036 <iunlockput>
    ilock(ip);
    8000577e:	8556                	mv	a0,s5
    80005780:	ffffe097          	auipc	ra,0xffffe
    80005784:	654080e7          	jalr	1620(ra) # 80003dd4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005788:	000b059b          	sext.w	a1,s6
    8000578c:	4789                	li	a5,2
    8000578e:	02f59563          	bne	a1,a5,800057b8 <create+0x8c>
    80005792:	044ad783          	lhu	a5,68(s5)
    80005796:	37f9                	addiw	a5,a5,-2
    80005798:	17c2                	slli	a5,a5,0x30
    8000579a:	93c1                	srli	a5,a5,0x30
    8000579c:	4705                	li	a4,1
    8000579e:	00f76d63          	bltu	a4,a5,800057b8 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800057a2:	8556                	mv	a0,s5
    800057a4:	60a6                	ld	ra,72(sp)
    800057a6:	6406                	ld	s0,64(sp)
    800057a8:	74e2                	ld	s1,56(sp)
    800057aa:	7942                	ld	s2,48(sp)
    800057ac:	79a2                	ld	s3,40(sp)
    800057ae:	7a02                	ld	s4,32(sp)
    800057b0:	6ae2                	ld	s5,24(sp)
    800057b2:	6b42                	ld	s6,16(sp)
    800057b4:	6161                	addi	sp,sp,80
    800057b6:	8082                	ret
    iunlockput(ip);
    800057b8:	8556                	mv	a0,s5
    800057ba:	fffff097          	auipc	ra,0xfffff
    800057be:	87c080e7          	jalr	-1924(ra) # 80004036 <iunlockput>
    return 0;
    800057c2:	4a81                	li	s5,0
    800057c4:	bff9                	j	800057a2 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800057c6:	85da                	mv	a1,s6
    800057c8:	4088                	lw	a0,0(s1)
    800057ca:	ffffe097          	auipc	ra,0xffffe
    800057ce:	46e080e7          	jalr	1134(ra) # 80003c38 <ialloc>
    800057d2:	8a2a                	mv	s4,a0
    800057d4:	c921                	beqz	a0,80005824 <create+0xf8>
  ilock(ip);
    800057d6:	ffffe097          	auipc	ra,0xffffe
    800057da:	5fe080e7          	jalr	1534(ra) # 80003dd4 <ilock>
  ip->major = major;
    800057de:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800057e2:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800057e6:	4785                	li	a5,1
    800057e8:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    800057ec:	8552                	mv	a0,s4
    800057ee:	ffffe097          	auipc	ra,0xffffe
    800057f2:	51c080e7          	jalr	1308(ra) # 80003d0a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800057f6:	000b059b          	sext.w	a1,s6
    800057fa:	4785                	li	a5,1
    800057fc:	02f58b63          	beq	a1,a5,80005832 <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    80005800:	004a2603          	lw	a2,4(s4)
    80005804:	fb040593          	addi	a1,s0,-80
    80005808:	8526                	mv	a0,s1
    8000580a:	fffff097          	auipc	ra,0xfffff
    8000580e:	cbe080e7          	jalr	-834(ra) # 800044c8 <dirlink>
    80005812:	06054f63          	bltz	a0,80005890 <create+0x164>
  iunlockput(dp);
    80005816:	8526                	mv	a0,s1
    80005818:	fffff097          	auipc	ra,0xfffff
    8000581c:	81e080e7          	jalr	-2018(ra) # 80004036 <iunlockput>
  return ip;
    80005820:	8ad2                	mv	s5,s4
    80005822:	b741                	j	800057a2 <create+0x76>
    iunlockput(dp);
    80005824:	8526                	mv	a0,s1
    80005826:	fffff097          	auipc	ra,0xfffff
    8000582a:	810080e7          	jalr	-2032(ra) # 80004036 <iunlockput>
    return 0;
    8000582e:	8ad2                	mv	s5,s4
    80005830:	bf8d                	j	800057a2 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005832:	004a2603          	lw	a2,4(s4)
    80005836:	00003597          	auipc	a1,0x3
    8000583a:	00a58593          	addi	a1,a1,10 # 80008840 <syscalls+0x2c8>
    8000583e:	8552                	mv	a0,s4
    80005840:	fffff097          	auipc	ra,0xfffff
    80005844:	c88080e7          	jalr	-888(ra) # 800044c8 <dirlink>
    80005848:	04054463          	bltz	a0,80005890 <create+0x164>
    8000584c:	40d0                	lw	a2,4(s1)
    8000584e:	00003597          	auipc	a1,0x3
    80005852:	ffa58593          	addi	a1,a1,-6 # 80008848 <syscalls+0x2d0>
    80005856:	8552                	mv	a0,s4
    80005858:	fffff097          	auipc	ra,0xfffff
    8000585c:	c70080e7          	jalr	-912(ra) # 800044c8 <dirlink>
    80005860:	02054863          	bltz	a0,80005890 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    80005864:	004a2603          	lw	a2,4(s4)
    80005868:	fb040593          	addi	a1,s0,-80
    8000586c:	8526                	mv	a0,s1
    8000586e:	fffff097          	auipc	ra,0xfffff
    80005872:	c5a080e7          	jalr	-934(ra) # 800044c8 <dirlink>
    80005876:	00054d63          	bltz	a0,80005890 <create+0x164>
    dp->nlink++;  // for ".."
    8000587a:	04a4d783          	lhu	a5,74(s1)
    8000587e:	2785                	addiw	a5,a5,1
    80005880:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005884:	8526                	mv	a0,s1
    80005886:	ffffe097          	auipc	ra,0xffffe
    8000588a:	484080e7          	jalr	1156(ra) # 80003d0a <iupdate>
    8000588e:	b761                	j	80005816 <create+0xea>
  ip->nlink = 0;
    80005890:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005894:	8552                	mv	a0,s4
    80005896:	ffffe097          	auipc	ra,0xffffe
    8000589a:	474080e7          	jalr	1140(ra) # 80003d0a <iupdate>
  iunlockput(ip);
    8000589e:	8552                	mv	a0,s4
    800058a0:	ffffe097          	auipc	ra,0xffffe
    800058a4:	796080e7          	jalr	1942(ra) # 80004036 <iunlockput>
  iunlockput(dp);
    800058a8:	8526                	mv	a0,s1
    800058aa:	ffffe097          	auipc	ra,0xffffe
    800058ae:	78c080e7          	jalr	1932(ra) # 80004036 <iunlockput>
  return 0;
    800058b2:	bdc5                	j	800057a2 <create+0x76>
    return 0;
    800058b4:	8aaa                	mv	s5,a0
    800058b6:	b5f5                	j	800057a2 <create+0x76>

00000000800058b8 <sys_dup>:
{
    800058b8:	7179                	addi	sp,sp,-48
    800058ba:	f406                	sd	ra,40(sp)
    800058bc:	f022                	sd	s0,32(sp)
    800058be:	ec26                	sd	s1,24(sp)
    800058c0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800058c2:	fd840613          	addi	a2,s0,-40
    800058c6:	4581                	li	a1,0
    800058c8:	4501                	li	a0,0
    800058ca:	00000097          	auipc	ra,0x0
    800058ce:	dc0080e7          	jalr	-576(ra) # 8000568a <argfd>
    return -1;
    800058d2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800058d4:	02054363          	bltz	a0,800058fa <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800058d8:	fd843503          	ld	a0,-40(s0)
    800058dc:	00000097          	auipc	ra,0x0
    800058e0:	e0e080e7          	jalr	-498(ra) # 800056ea <fdalloc>
    800058e4:	84aa                	mv	s1,a0
    return -1;
    800058e6:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800058e8:	00054963          	bltz	a0,800058fa <sys_dup+0x42>
  filedup(f);
    800058ec:	fd843503          	ld	a0,-40(s0)
    800058f0:	fffff097          	auipc	ra,0xfffff
    800058f4:	320080e7          	jalr	800(ra) # 80004c10 <filedup>
  return fd;
    800058f8:	87a6                	mv	a5,s1
}
    800058fa:	853e                	mv	a0,a5
    800058fc:	70a2                	ld	ra,40(sp)
    800058fe:	7402                	ld	s0,32(sp)
    80005900:	64e2                	ld	s1,24(sp)
    80005902:	6145                	addi	sp,sp,48
    80005904:	8082                	ret

0000000080005906 <sys_read>:
{
    80005906:	7179                	addi	sp,sp,-48
    80005908:	f406                	sd	ra,40(sp)
    8000590a:	f022                	sd	s0,32(sp)
    8000590c:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000590e:	fd840593          	addi	a1,s0,-40
    80005912:	4505                	li	a0,1
    80005914:	ffffd097          	auipc	ra,0xffffd
    80005918:	69e080e7          	jalr	1694(ra) # 80002fb2 <argaddr>
  argint(2, &n);
    8000591c:	fe440593          	addi	a1,s0,-28
    80005920:	4509                	li	a0,2
    80005922:	ffffd097          	auipc	ra,0xffffd
    80005926:	670080e7          	jalr	1648(ra) # 80002f92 <argint>
  if(argfd(0, 0, &f) < 0)
    8000592a:	fe840613          	addi	a2,s0,-24
    8000592e:	4581                	li	a1,0
    80005930:	4501                	li	a0,0
    80005932:	00000097          	auipc	ra,0x0
    80005936:	d58080e7          	jalr	-680(ra) # 8000568a <argfd>
    8000593a:	87aa                	mv	a5,a0
    return -1;
    8000593c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000593e:	0007cc63          	bltz	a5,80005956 <sys_read+0x50>
  return fileread(f, p, n);
    80005942:	fe442603          	lw	a2,-28(s0)
    80005946:	fd843583          	ld	a1,-40(s0)
    8000594a:	fe843503          	ld	a0,-24(s0)
    8000594e:	fffff097          	auipc	ra,0xfffff
    80005952:	44e080e7          	jalr	1102(ra) # 80004d9c <fileread>
}
    80005956:	70a2                	ld	ra,40(sp)
    80005958:	7402                	ld	s0,32(sp)
    8000595a:	6145                	addi	sp,sp,48
    8000595c:	8082                	ret

000000008000595e <sys_write>:
{
    8000595e:	7179                	addi	sp,sp,-48
    80005960:	f406                	sd	ra,40(sp)
    80005962:	f022                	sd	s0,32(sp)
    80005964:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005966:	fd840593          	addi	a1,s0,-40
    8000596a:	4505                	li	a0,1
    8000596c:	ffffd097          	auipc	ra,0xffffd
    80005970:	646080e7          	jalr	1606(ra) # 80002fb2 <argaddr>
  argint(2, &n);
    80005974:	fe440593          	addi	a1,s0,-28
    80005978:	4509                	li	a0,2
    8000597a:	ffffd097          	auipc	ra,0xffffd
    8000597e:	618080e7          	jalr	1560(ra) # 80002f92 <argint>
  if(argfd(0, 0, &f) < 0)
    80005982:	fe840613          	addi	a2,s0,-24
    80005986:	4581                	li	a1,0
    80005988:	4501                	li	a0,0
    8000598a:	00000097          	auipc	ra,0x0
    8000598e:	d00080e7          	jalr	-768(ra) # 8000568a <argfd>
    80005992:	87aa                	mv	a5,a0
    return -1;
    80005994:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005996:	0007cc63          	bltz	a5,800059ae <sys_write+0x50>
  return filewrite(f, p, n);
    8000599a:	fe442603          	lw	a2,-28(s0)
    8000599e:	fd843583          	ld	a1,-40(s0)
    800059a2:	fe843503          	ld	a0,-24(s0)
    800059a6:	fffff097          	auipc	ra,0xfffff
    800059aa:	4b8080e7          	jalr	1208(ra) # 80004e5e <filewrite>
}
    800059ae:	70a2                	ld	ra,40(sp)
    800059b0:	7402                	ld	s0,32(sp)
    800059b2:	6145                	addi	sp,sp,48
    800059b4:	8082                	ret

00000000800059b6 <sys_close>:
{
    800059b6:	1101                	addi	sp,sp,-32
    800059b8:	ec06                	sd	ra,24(sp)
    800059ba:	e822                	sd	s0,16(sp)
    800059bc:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800059be:	fe040613          	addi	a2,s0,-32
    800059c2:	fec40593          	addi	a1,s0,-20
    800059c6:	4501                	li	a0,0
    800059c8:	00000097          	auipc	ra,0x0
    800059cc:	cc2080e7          	jalr	-830(ra) # 8000568a <argfd>
    return -1;
    800059d0:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800059d2:	02054463          	bltz	a0,800059fa <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800059d6:	ffffc097          	auipc	ra,0xffffc
    800059da:	ff0080e7          	jalr	-16(ra) # 800019c6 <myproc>
    800059de:	fec42783          	lw	a5,-20(s0)
    800059e2:	07e9                	addi	a5,a5,26
    800059e4:	078e                	slli	a5,a5,0x3
    800059e6:	97aa                	add	a5,a5,a0
    800059e8:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800059ec:	fe043503          	ld	a0,-32(s0)
    800059f0:	fffff097          	auipc	ra,0xfffff
    800059f4:	272080e7          	jalr	626(ra) # 80004c62 <fileclose>
  return 0;
    800059f8:	4781                	li	a5,0
}
    800059fa:	853e                	mv	a0,a5
    800059fc:	60e2                	ld	ra,24(sp)
    800059fe:	6442                	ld	s0,16(sp)
    80005a00:	6105                	addi	sp,sp,32
    80005a02:	8082                	ret

0000000080005a04 <sys_fstat>:
{
    80005a04:	1101                	addi	sp,sp,-32
    80005a06:	ec06                	sd	ra,24(sp)
    80005a08:	e822                	sd	s0,16(sp)
    80005a0a:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005a0c:	fe040593          	addi	a1,s0,-32
    80005a10:	4505                	li	a0,1
    80005a12:	ffffd097          	auipc	ra,0xffffd
    80005a16:	5a0080e7          	jalr	1440(ra) # 80002fb2 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005a1a:	fe840613          	addi	a2,s0,-24
    80005a1e:	4581                	li	a1,0
    80005a20:	4501                	li	a0,0
    80005a22:	00000097          	auipc	ra,0x0
    80005a26:	c68080e7          	jalr	-920(ra) # 8000568a <argfd>
    80005a2a:	87aa                	mv	a5,a0
    return -1;
    80005a2c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005a2e:	0007ca63          	bltz	a5,80005a42 <sys_fstat+0x3e>
  return filestat(f, st);
    80005a32:	fe043583          	ld	a1,-32(s0)
    80005a36:	fe843503          	ld	a0,-24(s0)
    80005a3a:	fffff097          	auipc	ra,0xfffff
    80005a3e:	2f0080e7          	jalr	752(ra) # 80004d2a <filestat>
}
    80005a42:	60e2                	ld	ra,24(sp)
    80005a44:	6442                	ld	s0,16(sp)
    80005a46:	6105                	addi	sp,sp,32
    80005a48:	8082                	ret

0000000080005a4a <sys_link>:
{
    80005a4a:	7169                	addi	sp,sp,-304
    80005a4c:	f606                	sd	ra,296(sp)
    80005a4e:	f222                	sd	s0,288(sp)
    80005a50:	ee26                	sd	s1,280(sp)
    80005a52:	ea4a                	sd	s2,272(sp)
    80005a54:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a56:	08000613          	li	a2,128
    80005a5a:	ed040593          	addi	a1,s0,-304
    80005a5e:	4501                	li	a0,0
    80005a60:	ffffd097          	auipc	ra,0xffffd
    80005a64:	572080e7          	jalr	1394(ra) # 80002fd2 <argstr>
    return -1;
    80005a68:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a6a:	10054e63          	bltz	a0,80005b86 <sys_link+0x13c>
    80005a6e:	08000613          	li	a2,128
    80005a72:	f5040593          	addi	a1,s0,-176
    80005a76:	4505                	li	a0,1
    80005a78:	ffffd097          	auipc	ra,0xffffd
    80005a7c:	55a080e7          	jalr	1370(ra) # 80002fd2 <argstr>
    return -1;
    80005a80:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a82:	10054263          	bltz	a0,80005b86 <sys_link+0x13c>
  begin_op();
    80005a86:	fffff097          	auipc	ra,0xfffff
    80005a8a:	d10080e7          	jalr	-752(ra) # 80004796 <begin_op>
  if((ip = namei(old)) == 0){
    80005a8e:	ed040513          	addi	a0,s0,-304
    80005a92:	fffff097          	auipc	ra,0xfffff
    80005a96:	ae8080e7          	jalr	-1304(ra) # 8000457a <namei>
    80005a9a:	84aa                	mv	s1,a0
    80005a9c:	c551                	beqz	a0,80005b28 <sys_link+0xde>
  ilock(ip);
    80005a9e:	ffffe097          	auipc	ra,0xffffe
    80005aa2:	336080e7          	jalr	822(ra) # 80003dd4 <ilock>
  if(ip->type == T_DIR){
    80005aa6:	04449703          	lh	a4,68(s1)
    80005aaa:	4785                	li	a5,1
    80005aac:	08f70463          	beq	a4,a5,80005b34 <sys_link+0xea>
  ip->nlink++;
    80005ab0:	04a4d783          	lhu	a5,74(s1)
    80005ab4:	2785                	addiw	a5,a5,1
    80005ab6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005aba:	8526                	mv	a0,s1
    80005abc:	ffffe097          	auipc	ra,0xffffe
    80005ac0:	24e080e7          	jalr	590(ra) # 80003d0a <iupdate>
  iunlock(ip);
    80005ac4:	8526                	mv	a0,s1
    80005ac6:	ffffe097          	auipc	ra,0xffffe
    80005aca:	3d0080e7          	jalr	976(ra) # 80003e96 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005ace:	fd040593          	addi	a1,s0,-48
    80005ad2:	f5040513          	addi	a0,s0,-176
    80005ad6:	fffff097          	auipc	ra,0xfffff
    80005ada:	ac2080e7          	jalr	-1342(ra) # 80004598 <nameiparent>
    80005ade:	892a                	mv	s2,a0
    80005ae0:	c935                	beqz	a0,80005b54 <sys_link+0x10a>
  ilock(dp);
    80005ae2:	ffffe097          	auipc	ra,0xffffe
    80005ae6:	2f2080e7          	jalr	754(ra) # 80003dd4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005aea:	00092703          	lw	a4,0(s2)
    80005aee:	409c                	lw	a5,0(s1)
    80005af0:	04f71d63          	bne	a4,a5,80005b4a <sys_link+0x100>
    80005af4:	40d0                	lw	a2,4(s1)
    80005af6:	fd040593          	addi	a1,s0,-48
    80005afa:	854a                	mv	a0,s2
    80005afc:	fffff097          	auipc	ra,0xfffff
    80005b00:	9cc080e7          	jalr	-1588(ra) # 800044c8 <dirlink>
    80005b04:	04054363          	bltz	a0,80005b4a <sys_link+0x100>
  iunlockput(dp);
    80005b08:	854a                	mv	a0,s2
    80005b0a:	ffffe097          	auipc	ra,0xffffe
    80005b0e:	52c080e7          	jalr	1324(ra) # 80004036 <iunlockput>
  iput(ip);
    80005b12:	8526                	mv	a0,s1
    80005b14:	ffffe097          	auipc	ra,0xffffe
    80005b18:	47a080e7          	jalr	1146(ra) # 80003f8e <iput>
  end_op();
    80005b1c:	fffff097          	auipc	ra,0xfffff
    80005b20:	cfa080e7          	jalr	-774(ra) # 80004816 <end_op>
  return 0;
    80005b24:	4781                	li	a5,0
    80005b26:	a085                	j	80005b86 <sys_link+0x13c>
    end_op();
    80005b28:	fffff097          	auipc	ra,0xfffff
    80005b2c:	cee080e7          	jalr	-786(ra) # 80004816 <end_op>
    return -1;
    80005b30:	57fd                	li	a5,-1
    80005b32:	a891                	j	80005b86 <sys_link+0x13c>
    iunlockput(ip);
    80005b34:	8526                	mv	a0,s1
    80005b36:	ffffe097          	auipc	ra,0xffffe
    80005b3a:	500080e7          	jalr	1280(ra) # 80004036 <iunlockput>
    end_op();
    80005b3e:	fffff097          	auipc	ra,0xfffff
    80005b42:	cd8080e7          	jalr	-808(ra) # 80004816 <end_op>
    return -1;
    80005b46:	57fd                	li	a5,-1
    80005b48:	a83d                	j	80005b86 <sys_link+0x13c>
    iunlockput(dp);
    80005b4a:	854a                	mv	a0,s2
    80005b4c:	ffffe097          	auipc	ra,0xffffe
    80005b50:	4ea080e7          	jalr	1258(ra) # 80004036 <iunlockput>
  ilock(ip);
    80005b54:	8526                	mv	a0,s1
    80005b56:	ffffe097          	auipc	ra,0xffffe
    80005b5a:	27e080e7          	jalr	638(ra) # 80003dd4 <ilock>
  ip->nlink--;
    80005b5e:	04a4d783          	lhu	a5,74(s1)
    80005b62:	37fd                	addiw	a5,a5,-1
    80005b64:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b68:	8526                	mv	a0,s1
    80005b6a:	ffffe097          	auipc	ra,0xffffe
    80005b6e:	1a0080e7          	jalr	416(ra) # 80003d0a <iupdate>
  iunlockput(ip);
    80005b72:	8526                	mv	a0,s1
    80005b74:	ffffe097          	auipc	ra,0xffffe
    80005b78:	4c2080e7          	jalr	1218(ra) # 80004036 <iunlockput>
  end_op();
    80005b7c:	fffff097          	auipc	ra,0xfffff
    80005b80:	c9a080e7          	jalr	-870(ra) # 80004816 <end_op>
  return -1;
    80005b84:	57fd                	li	a5,-1
}
    80005b86:	853e                	mv	a0,a5
    80005b88:	70b2                	ld	ra,296(sp)
    80005b8a:	7412                	ld	s0,288(sp)
    80005b8c:	64f2                	ld	s1,280(sp)
    80005b8e:	6952                	ld	s2,272(sp)
    80005b90:	6155                	addi	sp,sp,304
    80005b92:	8082                	ret

0000000080005b94 <sys_unlink>:
{
    80005b94:	7151                	addi	sp,sp,-240
    80005b96:	f586                	sd	ra,232(sp)
    80005b98:	f1a2                	sd	s0,224(sp)
    80005b9a:	eda6                	sd	s1,216(sp)
    80005b9c:	e9ca                	sd	s2,208(sp)
    80005b9e:	e5ce                	sd	s3,200(sp)
    80005ba0:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005ba2:	08000613          	li	a2,128
    80005ba6:	f3040593          	addi	a1,s0,-208
    80005baa:	4501                	li	a0,0
    80005bac:	ffffd097          	auipc	ra,0xffffd
    80005bb0:	426080e7          	jalr	1062(ra) # 80002fd2 <argstr>
    80005bb4:	18054163          	bltz	a0,80005d36 <sys_unlink+0x1a2>
  begin_op();
    80005bb8:	fffff097          	auipc	ra,0xfffff
    80005bbc:	bde080e7          	jalr	-1058(ra) # 80004796 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005bc0:	fb040593          	addi	a1,s0,-80
    80005bc4:	f3040513          	addi	a0,s0,-208
    80005bc8:	fffff097          	auipc	ra,0xfffff
    80005bcc:	9d0080e7          	jalr	-1584(ra) # 80004598 <nameiparent>
    80005bd0:	84aa                	mv	s1,a0
    80005bd2:	c979                	beqz	a0,80005ca8 <sys_unlink+0x114>
  ilock(dp);
    80005bd4:	ffffe097          	auipc	ra,0xffffe
    80005bd8:	200080e7          	jalr	512(ra) # 80003dd4 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005bdc:	00003597          	auipc	a1,0x3
    80005be0:	c6458593          	addi	a1,a1,-924 # 80008840 <syscalls+0x2c8>
    80005be4:	fb040513          	addi	a0,s0,-80
    80005be8:	ffffe097          	auipc	ra,0xffffe
    80005bec:	6b6080e7          	jalr	1718(ra) # 8000429e <namecmp>
    80005bf0:	14050a63          	beqz	a0,80005d44 <sys_unlink+0x1b0>
    80005bf4:	00003597          	auipc	a1,0x3
    80005bf8:	c5458593          	addi	a1,a1,-940 # 80008848 <syscalls+0x2d0>
    80005bfc:	fb040513          	addi	a0,s0,-80
    80005c00:	ffffe097          	auipc	ra,0xffffe
    80005c04:	69e080e7          	jalr	1694(ra) # 8000429e <namecmp>
    80005c08:	12050e63          	beqz	a0,80005d44 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005c0c:	f2c40613          	addi	a2,s0,-212
    80005c10:	fb040593          	addi	a1,s0,-80
    80005c14:	8526                	mv	a0,s1
    80005c16:	ffffe097          	auipc	ra,0xffffe
    80005c1a:	6a2080e7          	jalr	1698(ra) # 800042b8 <dirlookup>
    80005c1e:	892a                	mv	s2,a0
    80005c20:	12050263          	beqz	a0,80005d44 <sys_unlink+0x1b0>
  ilock(ip);
    80005c24:	ffffe097          	auipc	ra,0xffffe
    80005c28:	1b0080e7          	jalr	432(ra) # 80003dd4 <ilock>
  if(ip->nlink < 1)
    80005c2c:	04a91783          	lh	a5,74(s2)
    80005c30:	08f05263          	blez	a5,80005cb4 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005c34:	04491703          	lh	a4,68(s2)
    80005c38:	4785                	li	a5,1
    80005c3a:	08f70563          	beq	a4,a5,80005cc4 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005c3e:	4641                	li	a2,16
    80005c40:	4581                	li	a1,0
    80005c42:	fc040513          	addi	a0,s0,-64
    80005c46:	ffffb097          	auipc	ra,0xffffb
    80005c4a:	0a0080e7          	jalr	160(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c4e:	4741                	li	a4,16
    80005c50:	f2c42683          	lw	a3,-212(s0)
    80005c54:	fc040613          	addi	a2,s0,-64
    80005c58:	4581                	li	a1,0
    80005c5a:	8526                	mv	a0,s1
    80005c5c:	ffffe097          	auipc	ra,0xffffe
    80005c60:	524080e7          	jalr	1316(ra) # 80004180 <writei>
    80005c64:	47c1                	li	a5,16
    80005c66:	0af51563          	bne	a0,a5,80005d10 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005c6a:	04491703          	lh	a4,68(s2)
    80005c6e:	4785                	li	a5,1
    80005c70:	0af70863          	beq	a4,a5,80005d20 <sys_unlink+0x18c>
  iunlockput(dp);
    80005c74:	8526                	mv	a0,s1
    80005c76:	ffffe097          	auipc	ra,0xffffe
    80005c7a:	3c0080e7          	jalr	960(ra) # 80004036 <iunlockput>
  ip->nlink--;
    80005c7e:	04a95783          	lhu	a5,74(s2)
    80005c82:	37fd                	addiw	a5,a5,-1
    80005c84:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005c88:	854a                	mv	a0,s2
    80005c8a:	ffffe097          	auipc	ra,0xffffe
    80005c8e:	080080e7          	jalr	128(ra) # 80003d0a <iupdate>
  iunlockput(ip);
    80005c92:	854a                	mv	a0,s2
    80005c94:	ffffe097          	auipc	ra,0xffffe
    80005c98:	3a2080e7          	jalr	930(ra) # 80004036 <iunlockput>
  end_op();
    80005c9c:	fffff097          	auipc	ra,0xfffff
    80005ca0:	b7a080e7          	jalr	-1158(ra) # 80004816 <end_op>
  return 0;
    80005ca4:	4501                	li	a0,0
    80005ca6:	a84d                	j	80005d58 <sys_unlink+0x1c4>
    end_op();
    80005ca8:	fffff097          	auipc	ra,0xfffff
    80005cac:	b6e080e7          	jalr	-1170(ra) # 80004816 <end_op>
    return -1;
    80005cb0:	557d                	li	a0,-1
    80005cb2:	a05d                	j	80005d58 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005cb4:	00003517          	auipc	a0,0x3
    80005cb8:	b9c50513          	addi	a0,a0,-1124 # 80008850 <syscalls+0x2d8>
    80005cbc:	ffffb097          	auipc	ra,0xffffb
    80005cc0:	888080e7          	jalr	-1912(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005cc4:	04c92703          	lw	a4,76(s2)
    80005cc8:	02000793          	li	a5,32
    80005ccc:	f6e7f9e3          	bgeu	a5,a4,80005c3e <sys_unlink+0xaa>
    80005cd0:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005cd4:	4741                	li	a4,16
    80005cd6:	86ce                	mv	a3,s3
    80005cd8:	f1840613          	addi	a2,s0,-232
    80005cdc:	4581                	li	a1,0
    80005cde:	854a                	mv	a0,s2
    80005ce0:	ffffe097          	auipc	ra,0xffffe
    80005ce4:	3a8080e7          	jalr	936(ra) # 80004088 <readi>
    80005ce8:	47c1                	li	a5,16
    80005cea:	00f51b63          	bne	a0,a5,80005d00 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005cee:	f1845783          	lhu	a5,-232(s0)
    80005cf2:	e7a1                	bnez	a5,80005d3a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005cf4:	29c1                	addiw	s3,s3,16
    80005cf6:	04c92783          	lw	a5,76(s2)
    80005cfa:	fcf9ede3          	bltu	s3,a5,80005cd4 <sys_unlink+0x140>
    80005cfe:	b781                	j	80005c3e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005d00:	00003517          	auipc	a0,0x3
    80005d04:	b6850513          	addi	a0,a0,-1176 # 80008868 <syscalls+0x2f0>
    80005d08:	ffffb097          	auipc	ra,0xffffb
    80005d0c:	83c080e7          	jalr	-1988(ra) # 80000544 <panic>
    panic("unlink: writei");
    80005d10:	00003517          	auipc	a0,0x3
    80005d14:	b7050513          	addi	a0,a0,-1168 # 80008880 <syscalls+0x308>
    80005d18:	ffffb097          	auipc	ra,0xffffb
    80005d1c:	82c080e7          	jalr	-2004(ra) # 80000544 <panic>
    dp->nlink--;
    80005d20:	04a4d783          	lhu	a5,74(s1)
    80005d24:	37fd                	addiw	a5,a5,-1
    80005d26:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005d2a:	8526                	mv	a0,s1
    80005d2c:	ffffe097          	auipc	ra,0xffffe
    80005d30:	fde080e7          	jalr	-34(ra) # 80003d0a <iupdate>
    80005d34:	b781                	j	80005c74 <sys_unlink+0xe0>
    return -1;
    80005d36:	557d                	li	a0,-1
    80005d38:	a005                	j	80005d58 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005d3a:	854a                	mv	a0,s2
    80005d3c:	ffffe097          	auipc	ra,0xffffe
    80005d40:	2fa080e7          	jalr	762(ra) # 80004036 <iunlockput>
  iunlockput(dp);
    80005d44:	8526                	mv	a0,s1
    80005d46:	ffffe097          	auipc	ra,0xffffe
    80005d4a:	2f0080e7          	jalr	752(ra) # 80004036 <iunlockput>
  end_op();
    80005d4e:	fffff097          	auipc	ra,0xfffff
    80005d52:	ac8080e7          	jalr	-1336(ra) # 80004816 <end_op>
  return -1;
    80005d56:	557d                	li	a0,-1
}
    80005d58:	70ae                	ld	ra,232(sp)
    80005d5a:	740e                	ld	s0,224(sp)
    80005d5c:	64ee                	ld	s1,216(sp)
    80005d5e:	694e                	ld	s2,208(sp)
    80005d60:	69ae                	ld	s3,200(sp)
    80005d62:	616d                	addi	sp,sp,240
    80005d64:	8082                	ret

0000000080005d66 <sys_open>:

uint64
sys_open(void)
{
    80005d66:	7131                	addi	sp,sp,-192
    80005d68:	fd06                	sd	ra,184(sp)
    80005d6a:	f922                	sd	s0,176(sp)
    80005d6c:	f526                	sd	s1,168(sp)
    80005d6e:	f14a                	sd	s2,160(sp)
    80005d70:	ed4e                	sd	s3,152(sp)
    80005d72:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005d74:	f4c40593          	addi	a1,s0,-180
    80005d78:	4505                	li	a0,1
    80005d7a:	ffffd097          	auipc	ra,0xffffd
    80005d7e:	218080e7          	jalr	536(ra) # 80002f92 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005d82:	08000613          	li	a2,128
    80005d86:	f5040593          	addi	a1,s0,-176
    80005d8a:	4501                	li	a0,0
    80005d8c:	ffffd097          	auipc	ra,0xffffd
    80005d90:	246080e7          	jalr	582(ra) # 80002fd2 <argstr>
    80005d94:	87aa                	mv	a5,a0
    return -1;
    80005d96:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005d98:	0a07c963          	bltz	a5,80005e4a <sys_open+0xe4>

  begin_op();
    80005d9c:	fffff097          	auipc	ra,0xfffff
    80005da0:	9fa080e7          	jalr	-1542(ra) # 80004796 <begin_op>

  if(omode & O_CREATE){
    80005da4:	f4c42783          	lw	a5,-180(s0)
    80005da8:	2007f793          	andi	a5,a5,512
    80005dac:	cfc5                	beqz	a5,80005e64 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005dae:	4681                	li	a3,0
    80005db0:	4601                	li	a2,0
    80005db2:	4589                	li	a1,2
    80005db4:	f5040513          	addi	a0,s0,-176
    80005db8:	00000097          	auipc	ra,0x0
    80005dbc:	974080e7          	jalr	-1676(ra) # 8000572c <create>
    80005dc0:	84aa                	mv	s1,a0
    if(ip == 0){
    80005dc2:	c959                	beqz	a0,80005e58 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005dc4:	04449703          	lh	a4,68(s1)
    80005dc8:	478d                	li	a5,3
    80005dca:	00f71763          	bne	a4,a5,80005dd8 <sys_open+0x72>
    80005dce:	0464d703          	lhu	a4,70(s1)
    80005dd2:	47a5                	li	a5,9
    80005dd4:	0ce7ed63          	bltu	a5,a4,80005eae <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005dd8:	fffff097          	auipc	ra,0xfffff
    80005ddc:	dce080e7          	jalr	-562(ra) # 80004ba6 <filealloc>
    80005de0:	89aa                	mv	s3,a0
    80005de2:	10050363          	beqz	a0,80005ee8 <sys_open+0x182>
    80005de6:	00000097          	auipc	ra,0x0
    80005dea:	904080e7          	jalr	-1788(ra) # 800056ea <fdalloc>
    80005dee:	892a                	mv	s2,a0
    80005df0:	0e054763          	bltz	a0,80005ede <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005df4:	04449703          	lh	a4,68(s1)
    80005df8:	478d                	li	a5,3
    80005dfa:	0cf70563          	beq	a4,a5,80005ec4 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005dfe:	4789                	li	a5,2
    80005e00:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005e04:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005e08:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005e0c:	f4c42783          	lw	a5,-180(s0)
    80005e10:	0017c713          	xori	a4,a5,1
    80005e14:	8b05                	andi	a4,a4,1
    80005e16:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005e1a:	0037f713          	andi	a4,a5,3
    80005e1e:	00e03733          	snez	a4,a4
    80005e22:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005e26:	4007f793          	andi	a5,a5,1024
    80005e2a:	c791                	beqz	a5,80005e36 <sys_open+0xd0>
    80005e2c:	04449703          	lh	a4,68(s1)
    80005e30:	4789                	li	a5,2
    80005e32:	0af70063          	beq	a4,a5,80005ed2 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005e36:	8526                	mv	a0,s1
    80005e38:	ffffe097          	auipc	ra,0xffffe
    80005e3c:	05e080e7          	jalr	94(ra) # 80003e96 <iunlock>
  end_op();
    80005e40:	fffff097          	auipc	ra,0xfffff
    80005e44:	9d6080e7          	jalr	-1578(ra) # 80004816 <end_op>

  return fd;
    80005e48:	854a                	mv	a0,s2
}
    80005e4a:	70ea                	ld	ra,184(sp)
    80005e4c:	744a                	ld	s0,176(sp)
    80005e4e:	74aa                	ld	s1,168(sp)
    80005e50:	790a                	ld	s2,160(sp)
    80005e52:	69ea                	ld	s3,152(sp)
    80005e54:	6129                	addi	sp,sp,192
    80005e56:	8082                	ret
      end_op();
    80005e58:	fffff097          	auipc	ra,0xfffff
    80005e5c:	9be080e7          	jalr	-1602(ra) # 80004816 <end_op>
      return -1;
    80005e60:	557d                	li	a0,-1
    80005e62:	b7e5                	j	80005e4a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005e64:	f5040513          	addi	a0,s0,-176
    80005e68:	ffffe097          	auipc	ra,0xffffe
    80005e6c:	712080e7          	jalr	1810(ra) # 8000457a <namei>
    80005e70:	84aa                	mv	s1,a0
    80005e72:	c905                	beqz	a0,80005ea2 <sys_open+0x13c>
    ilock(ip);
    80005e74:	ffffe097          	auipc	ra,0xffffe
    80005e78:	f60080e7          	jalr	-160(ra) # 80003dd4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005e7c:	04449703          	lh	a4,68(s1)
    80005e80:	4785                	li	a5,1
    80005e82:	f4f711e3          	bne	a4,a5,80005dc4 <sys_open+0x5e>
    80005e86:	f4c42783          	lw	a5,-180(s0)
    80005e8a:	d7b9                	beqz	a5,80005dd8 <sys_open+0x72>
      iunlockput(ip);
    80005e8c:	8526                	mv	a0,s1
    80005e8e:	ffffe097          	auipc	ra,0xffffe
    80005e92:	1a8080e7          	jalr	424(ra) # 80004036 <iunlockput>
      end_op();
    80005e96:	fffff097          	auipc	ra,0xfffff
    80005e9a:	980080e7          	jalr	-1664(ra) # 80004816 <end_op>
      return -1;
    80005e9e:	557d                	li	a0,-1
    80005ea0:	b76d                	j	80005e4a <sys_open+0xe4>
      end_op();
    80005ea2:	fffff097          	auipc	ra,0xfffff
    80005ea6:	974080e7          	jalr	-1676(ra) # 80004816 <end_op>
      return -1;
    80005eaa:	557d                	li	a0,-1
    80005eac:	bf79                	j	80005e4a <sys_open+0xe4>
    iunlockput(ip);
    80005eae:	8526                	mv	a0,s1
    80005eb0:	ffffe097          	auipc	ra,0xffffe
    80005eb4:	186080e7          	jalr	390(ra) # 80004036 <iunlockput>
    end_op();
    80005eb8:	fffff097          	auipc	ra,0xfffff
    80005ebc:	95e080e7          	jalr	-1698(ra) # 80004816 <end_op>
    return -1;
    80005ec0:	557d                	li	a0,-1
    80005ec2:	b761                	j	80005e4a <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005ec4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005ec8:	04649783          	lh	a5,70(s1)
    80005ecc:	02f99223          	sh	a5,36(s3)
    80005ed0:	bf25                	j	80005e08 <sys_open+0xa2>
    itrunc(ip);
    80005ed2:	8526                	mv	a0,s1
    80005ed4:	ffffe097          	auipc	ra,0xffffe
    80005ed8:	00e080e7          	jalr	14(ra) # 80003ee2 <itrunc>
    80005edc:	bfa9                	j	80005e36 <sys_open+0xd0>
      fileclose(f);
    80005ede:	854e                	mv	a0,s3
    80005ee0:	fffff097          	auipc	ra,0xfffff
    80005ee4:	d82080e7          	jalr	-638(ra) # 80004c62 <fileclose>
    iunlockput(ip);
    80005ee8:	8526                	mv	a0,s1
    80005eea:	ffffe097          	auipc	ra,0xffffe
    80005eee:	14c080e7          	jalr	332(ra) # 80004036 <iunlockput>
    end_op();
    80005ef2:	fffff097          	auipc	ra,0xfffff
    80005ef6:	924080e7          	jalr	-1756(ra) # 80004816 <end_op>
    return -1;
    80005efa:	557d                	li	a0,-1
    80005efc:	b7b9                	j	80005e4a <sys_open+0xe4>

0000000080005efe <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005efe:	7175                	addi	sp,sp,-144
    80005f00:	e506                	sd	ra,136(sp)
    80005f02:	e122                	sd	s0,128(sp)
    80005f04:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005f06:	fffff097          	auipc	ra,0xfffff
    80005f0a:	890080e7          	jalr	-1904(ra) # 80004796 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005f0e:	08000613          	li	a2,128
    80005f12:	f7040593          	addi	a1,s0,-144
    80005f16:	4501                	li	a0,0
    80005f18:	ffffd097          	auipc	ra,0xffffd
    80005f1c:	0ba080e7          	jalr	186(ra) # 80002fd2 <argstr>
    80005f20:	02054963          	bltz	a0,80005f52 <sys_mkdir+0x54>
    80005f24:	4681                	li	a3,0
    80005f26:	4601                	li	a2,0
    80005f28:	4585                	li	a1,1
    80005f2a:	f7040513          	addi	a0,s0,-144
    80005f2e:	fffff097          	auipc	ra,0xfffff
    80005f32:	7fe080e7          	jalr	2046(ra) # 8000572c <create>
    80005f36:	cd11                	beqz	a0,80005f52 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f38:	ffffe097          	auipc	ra,0xffffe
    80005f3c:	0fe080e7          	jalr	254(ra) # 80004036 <iunlockput>
  end_op();
    80005f40:	fffff097          	auipc	ra,0xfffff
    80005f44:	8d6080e7          	jalr	-1834(ra) # 80004816 <end_op>
  return 0;
    80005f48:	4501                	li	a0,0
}
    80005f4a:	60aa                	ld	ra,136(sp)
    80005f4c:	640a                	ld	s0,128(sp)
    80005f4e:	6149                	addi	sp,sp,144
    80005f50:	8082                	ret
    end_op();
    80005f52:	fffff097          	auipc	ra,0xfffff
    80005f56:	8c4080e7          	jalr	-1852(ra) # 80004816 <end_op>
    return -1;
    80005f5a:	557d                	li	a0,-1
    80005f5c:	b7fd                	j	80005f4a <sys_mkdir+0x4c>

0000000080005f5e <sys_mknod>:

uint64
sys_mknod(void)
{
    80005f5e:	7135                	addi	sp,sp,-160
    80005f60:	ed06                	sd	ra,152(sp)
    80005f62:	e922                	sd	s0,144(sp)
    80005f64:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005f66:	fffff097          	auipc	ra,0xfffff
    80005f6a:	830080e7          	jalr	-2000(ra) # 80004796 <begin_op>
  argint(1, &major);
    80005f6e:	f6c40593          	addi	a1,s0,-148
    80005f72:	4505                	li	a0,1
    80005f74:	ffffd097          	auipc	ra,0xffffd
    80005f78:	01e080e7          	jalr	30(ra) # 80002f92 <argint>
  argint(2, &minor);
    80005f7c:	f6840593          	addi	a1,s0,-152
    80005f80:	4509                	li	a0,2
    80005f82:	ffffd097          	auipc	ra,0xffffd
    80005f86:	010080e7          	jalr	16(ra) # 80002f92 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f8a:	08000613          	li	a2,128
    80005f8e:	f7040593          	addi	a1,s0,-144
    80005f92:	4501                	li	a0,0
    80005f94:	ffffd097          	auipc	ra,0xffffd
    80005f98:	03e080e7          	jalr	62(ra) # 80002fd2 <argstr>
    80005f9c:	02054b63          	bltz	a0,80005fd2 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005fa0:	f6841683          	lh	a3,-152(s0)
    80005fa4:	f6c41603          	lh	a2,-148(s0)
    80005fa8:	458d                	li	a1,3
    80005faa:	f7040513          	addi	a0,s0,-144
    80005fae:	fffff097          	auipc	ra,0xfffff
    80005fb2:	77e080e7          	jalr	1918(ra) # 8000572c <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005fb6:	cd11                	beqz	a0,80005fd2 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005fb8:	ffffe097          	auipc	ra,0xffffe
    80005fbc:	07e080e7          	jalr	126(ra) # 80004036 <iunlockput>
  end_op();
    80005fc0:	fffff097          	auipc	ra,0xfffff
    80005fc4:	856080e7          	jalr	-1962(ra) # 80004816 <end_op>
  return 0;
    80005fc8:	4501                	li	a0,0
}
    80005fca:	60ea                	ld	ra,152(sp)
    80005fcc:	644a                	ld	s0,144(sp)
    80005fce:	610d                	addi	sp,sp,160
    80005fd0:	8082                	ret
    end_op();
    80005fd2:	fffff097          	auipc	ra,0xfffff
    80005fd6:	844080e7          	jalr	-1980(ra) # 80004816 <end_op>
    return -1;
    80005fda:	557d                	li	a0,-1
    80005fdc:	b7fd                	j	80005fca <sys_mknod+0x6c>

0000000080005fde <sys_chdir>:

uint64
sys_chdir(void)
{
    80005fde:	7135                	addi	sp,sp,-160
    80005fe0:	ed06                	sd	ra,152(sp)
    80005fe2:	e922                	sd	s0,144(sp)
    80005fe4:	e526                	sd	s1,136(sp)
    80005fe6:	e14a                	sd	s2,128(sp)
    80005fe8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005fea:	ffffc097          	auipc	ra,0xffffc
    80005fee:	9dc080e7          	jalr	-1572(ra) # 800019c6 <myproc>
    80005ff2:	892a                	mv	s2,a0
  
  begin_op();
    80005ff4:	ffffe097          	auipc	ra,0xffffe
    80005ff8:	7a2080e7          	jalr	1954(ra) # 80004796 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ffc:	08000613          	li	a2,128
    80006000:	f6040593          	addi	a1,s0,-160
    80006004:	4501                	li	a0,0
    80006006:	ffffd097          	auipc	ra,0xffffd
    8000600a:	fcc080e7          	jalr	-52(ra) # 80002fd2 <argstr>
    8000600e:	04054b63          	bltz	a0,80006064 <sys_chdir+0x86>
    80006012:	f6040513          	addi	a0,s0,-160
    80006016:	ffffe097          	auipc	ra,0xffffe
    8000601a:	564080e7          	jalr	1380(ra) # 8000457a <namei>
    8000601e:	84aa                	mv	s1,a0
    80006020:	c131                	beqz	a0,80006064 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006022:	ffffe097          	auipc	ra,0xffffe
    80006026:	db2080e7          	jalr	-590(ra) # 80003dd4 <ilock>
  if(ip->type != T_DIR){
    8000602a:	04449703          	lh	a4,68(s1)
    8000602e:	4785                	li	a5,1
    80006030:	04f71063          	bne	a4,a5,80006070 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006034:	8526                	mv	a0,s1
    80006036:	ffffe097          	auipc	ra,0xffffe
    8000603a:	e60080e7          	jalr	-416(ra) # 80003e96 <iunlock>
  iput(p->cwd);
    8000603e:	15093503          	ld	a0,336(s2)
    80006042:	ffffe097          	auipc	ra,0xffffe
    80006046:	f4c080e7          	jalr	-180(ra) # 80003f8e <iput>
  end_op();
    8000604a:	ffffe097          	auipc	ra,0xffffe
    8000604e:	7cc080e7          	jalr	1996(ra) # 80004816 <end_op>
  p->cwd = ip;
    80006052:	14993823          	sd	s1,336(s2)
  return 0;
    80006056:	4501                	li	a0,0
}
    80006058:	60ea                	ld	ra,152(sp)
    8000605a:	644a                	ld	s0,144(sp)
    8000605c:	64aa                	ld	s1,136(sp)
    8000605e:	690a                	ld	s2,128(sp)
    80006060:	610d                	addi	sp,sp,160
    80006062:	8082                	ret
    end_op();
    80006064:	ffffe097          	auipc	ra,0xffffe
    80006068:	7b2080e7          	jalr	1970(ra) # 80004816 <end_op>
    return -1;
    8000606c:	557d                	li	a0,-1
    8000606e:	b7ed                	j	80006058 <sys_chdir+0x7a>
    iunlockput(ip);
    80006070:	8526                	mv	a0,s1
    80006072:	ffffe097          	auipc	ra,0xffffe
    80006076:	fc4080e7          	jalr	-60(ra) # 80004036 <iunlockput>
    end_op();
    8000607a:	ffffe097          	auipc	ra,0xffffe
    8000607e:	79c080e7          	jalr	1948(ra) # 80004816 <end_op>
    return -1;
    80006082:	557d                	li	a0,-1
    80006084:	bfd1                	j	80006058 <sys_chdir+0x7a>

0000000080006086 <sys_exec>:

uint64
sys_exec(void)
{
    80006086:	7145                	addi	sp,sp,-464
    80006088:	e786                	sd	ra,456(sp)
    8000608a:	e3a2                	sd	s0,448(sp)
    8000608c:	ff26                	sd	s1,440(sp)
    8000608e:	fb4a                	sd	s2,432(sp)
    80006090:	f74e                	sd	s3,424(sp)
    80006092:	f352                	sd	s4,416(sp)
    80006094:	ef56                	sd	s5,408(sp)
    80006096:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80006098:	e3840593          	addi	a1,s0,-456
    8000609c:	4505                	li	a0,1
    8000609e:	ffffd097          	auipc	ra,0xffffd
    800060a2:	f14080e7          	jalr	-236(ra) # 80002fb2 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800060a6:	08000613          	li	a2,128
    800060aa:	f4040593          	addi	a1,s0,-192
    800060ae:	4501                	li	a0,0
    800060b0:	ffffd097          	auipc	ra,0xffffd
    800060b4:	f22080e7          	jalr	-222(ra) # 80002fd2 <argstr>
    800060b8:	87aa                	mv	a5,a0
    return -1;
    800060ba:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    800060bc:	0c07c263          	bltz	a5,80006180 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800060c0:	10000613          	li	a2,256
    800060c4:	4581                	li	a1,0
    800060c6:	e4040513          	addi	a0,s0,-448
    800060ca:	ffffb097          	auipc	ra,0xffffb
    800060ce:	c1c080e7          	jalr	-996(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800060d2:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800060d6:	89a6                	mv	s3,s1
    800060d8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800060da:	02000a13          	li	s4,32
    800060de:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800060e2:	00391513          	slli	a0,s2,0x3
    800060e6:	e3040593          	addi	a1,s0,-464
    800060ea:	e3843783          	ld	a5,-456(s0)
    800060ee:	953e                	add	a0,a0,a5
    800060f0:	ffffd097          	auipc	ra,0xffffd
    800060f4:	e04080e7          	jalr	-508(ra) # 80002ef4 <fetchaddr>
    800060f8:	02054a63          	bltz	a0,8000612c <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    800060fc:	e3043783          	ld	a5,-464(s0)
    80006100:	c3b9                	beqz	a5,80006146 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006102:	ffffb097          	auipc	ra,0xffffb
    80006106:	9f8080e7          	jalr	-1544(ra) # 80000afa <kalloc>
    8000610a:	85aa                	mv	a1,a0
    8000610c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006110:	cd11                	beqz	a0,8000612c <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006112:	6605                	lui	a2,0x1
    80006114:	e3043503          	ld	a0,-464(s0)
    80006118:	ffffd097          	auipc	ra,0xffffd
    8000611c:	e2e080e7          	jalr	-466(ra) # 80002f46 <fetchstr>
    80006120:	00054663          	bltz	a0,8000612c <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80006124:	0905                	addi	s2,s2,1
    80006126:	09a1                	addi	s3,s3,8
    80006128:	fb491be3          	bne	s2,s4,800060de <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000612c:	10048913          	addi	s2,s1,256
    80006130:	6088                	ld	a0,0(s1)
    80006132:	c531                	beqz	a0,8000617e <sys_exec+0xf8>
    kfree(argv[i]);
    80006134:	ffffb097          	auipc	ra,0xffffb
    80006138:	8ca080e7          	jalr	-1846(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000613c:	04a1                	addi	s1,s1,8
    8000613e:	ff2499e3          	bne	s1,s2,80006130 <sys_exec+0xaa>
  return -1;
    80006142:	557d                	li	a0,-1
    80006144:	a835                	j	80006180 <sys_exec+0xfa>
      argv[i] = 0;
    80006146:	0a8e                	slli	s5,s5,0x3
    80006148:	fc040793          	addi	a5,s0,-64
    8000614c:	9abe                	add	s5,s5,a5
    8000614e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006152:	e4040593          	addi	a1,s0,-448
    80006156:	f4040513          	addi	a0,s0,-192
    8000615a:	fffff097          	auipc	ra,0xfffff
    8000615e:	190080e7          	jalr	400(ra) # 800052ea <exec>
    80006162:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006164:	10048993          	addi	s3,s1,256
    80006168:	6088                	ld	a0,0(s1)
    8000616a:	c901                	beqz	a0,8000617a <sys_exec+0xf4>
    kfree(argv[i]);
    8000616c:	ffffb097          	auipc	ra,0xffffb
    80006170:	892080e7          	jalr	-1902(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006174:	04a1                	addi	s1,s1,8
    80006176:	ff3499e3          	bne	s1,s3,80006168 <sys_exec+0xe2>
  return ret;
    8000617a:	854a                	mv	a0,s2
    8000617c:	a011                	j	80006180 <sys_exec+0xfa>
  return -1;
    8000617e:	557d                	li	a0,-1
}
    80006180:	60be                	ld	ra,456(sp)
    80006182:	641e                	ld	s0,448(sp)
    80006184:	74fa                	ld	s1,440(sp)
    80006186:	795a                	ld	s2,432(sp)
    80006188:	79ba                	ld	s3,424(sp)
    8000618a:	7a1a                	ld	s4,416(sp)
    8000618c:	6afa                	ld	s5,408(sp)
    8000618e:	6179                	addi	sp,sp,464
    80006190:	8082                	ret

0000000080006192 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006192:	7139                	addi	sp,sp,-64
    80006194:	fc06                	sd	ra,56(sp)
    80006196:	f822                	sd	s0,48(sp)
    80006198:	f426                	sd	s1,40(sp)
    8000619a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000619c:	ffffc097          	auipc	ra,0xffffc
    800061a0:	82a080e7          	jalr	-2006(ra) # 800019c6 <myproc>
    800061a4:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800061a6:	fd840593          	addi	a1,s0,-40
    800061aa:	4501                	li	a0,0
    800061ac:	ffffd097          	auipc	ra,0xffffd
    800061b0:	e06080e7          	jalr	-506(ra) # 80002fb2 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800061b4:	fc840593          	addi	a1,s0,-56
    800061b8:	fd040513          	addi	a0,s0,-48
    800061bc:	fffff097          	auipc	ra,0xfffff
    800061c0:	dd6080e7          	jalr	-554(ra) # 80004f92 <pipealloc>
    return -1;
    800061c4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800061c6:	0c054463          	bltz	a0,8000628e <sys_pipe+0xfc>
  fd0 = -1;
    800061ca:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800061ce:	fd043503          	ld	a0,-48(s0)
    800061d2:	fffff097          	auipc	ra,0xfffff
    800061d6:	518080e7          	jalr	1304(ra) # 800056ea <fdalloc>
    800061da:	fca42223          	sw	a0,-60(s0)
    800061de:	08054b63          	bltz	a0,80006274 <sys_pipe+0xe2>
    800061e2:	fc843503          	ld	a0,-56(s0)
    800061e6:	fffff097          	auipc	ra,0xfffff
    800061ea:	504080e7          	jalr	1284(ra) # 800056ea <fdalloc>
    800061ee:	fca42023          	sw	a0,-64(s0)
    800061f2:	06054863          	bltz	a0,80006262 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800061f6:	4691                	li	a3,4
    800061f8:	fc440613          	addi	a2,s0,-60
    800061fc:	fd843583          	ld	a1,-40(s0)
    80006200:	68a8                	ld	a0,80(s1)
    80006202:	ffffb097          	auipc	ra,0xffffb
    80006206:	482080e7          	jalr	1154(ra) # 80001684 <copyout>
    8000620a:	02054063          	bltz	a0,8000622a <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000620e:	4691                	li	a3,4
    80006210:	fc040613          	addi	a2,s0,-64
    80006214:	fd843583          	ld	a1,-40(s0)
    80006218:	0591                	addi	a1,a1,4
    8000621a:	68a8                	ld	a0,80(s1)
    8000621c:	ffffb097          	auipc	ra,0xffffb
    80006220:	468080e7          	jalr	1128(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006224:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006226:	06055463          	bgez	a0,8000628e <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    8000622a:	fc442783          	lw	a5,-60(s0)
    8000622e:	07e9                	addi	a5,a5,26
    80006230:	078e                	slli	a5,a5,0x3
    80006232:	97a6                	add	a5,a5,s1
    80006234:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006238:	fc042503          	lw	a0,-64(s0)
    8000623c:	0569                	addi	a0,a0,26
    8000623e:	050e                	slli	a0,a0,0x3
    80006240:	94aa                	add	s1,s1,a0
    80006242:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006246:	fd043503          	ld	a0,-48(s0)
    8000624a:	fffff097          	auipc	ra,0xfffff
    8000624e:	a18080e7          	jalr	-1512(ra) # 80004c62 <fileclose>
    fileclose(wf);
    80006252:	fc843503          	ld	a0,-56(s0)
    80006256:	fffff097          	auipc	ra,0xfffff
    8000625a:	a0c080e7          	jalr	-1524(ra) # 80004c62 <fileclose>
    return -1;
    8000625e:	57fd                	li	a5,-1
    80006260:	a03d                	j	8000628e <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006262:	fc442783          	lw	a5,-60(s0)
    80006266:	0007c763          	bltz	a5,80006274 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    8000626a:	07e9                	addi	a5,a5,26
    8000626c:	078e                	slli	a5,a5,0x3
    8000626e:	94be                	add	s1,s1,a5
    80006270:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006274:	fd043503          	ld	a0,-48(s0)
    80006278:	fffff097          	auipc	ra,0xfffff
    8000627c:	9ea080e7          	jalr	-1558(ra) # 80004c62 <fileclose>
    fileclose(wf);
    80006280:	fc843503          	ld	a0,-56(s0)
    80006284:	fffff097          	auipc	ra,0xfffff
    80006288:	9de080e7          	jalr	-1570(ra) # 80004c62 <fileclose>
    return -1;
    8000628c:	57fd                	li	a5,-1
}
    8000628e:	853e                	mv	a0,a5
    80006290:	70e2                	ld	ra,56(sp)
    80006292:	7442                	ld	s0,48(sp)
    80006294:	74a2                	ld	s1,40(sp)
    80006296:	6121                	addi	sp,sp,64
    80006298:	8082                	ret
    8000629a:	0000                	unimp
    8000629c:	0000                	unimp
	...

00000000800062a0 <kernelvec>:
    800062a0:	7111                	addi	sp,sp,-256
    800062a2:	e006                	sd	ra,0(sp)
    800062a4:	e40a                	sd	sp,8(sp)
    800062a6:	e80e                	sd	gp,16(sp)
    800062a8:	ec12                	sd	tp,24(sp)
    800062aa:	f016                	sd	t0,32(sp)
    800062ac:	f41a                	sd	t1,40(sp)
    800062ae:	f81e                	sd	t2,48(sp)
    800062b0:	fc22                	sd	s0,56(sp)
    800062b2:	e0a6                	sd	s1,64(sp)
    800062b4:	e4aa                	sd	a0,72(sp)
    800062b6:	e8ae                	sd	a1,80(sp)
    800062b8:	ecb2                	sd	a2,88(sp)
    800062ba:	f0b6                	sd	a3,96(sp)
    800062bc:	f4ba                	sd	a4,104(sp)
    800062be:	f8be                	sd	a5,112(sp)
    800062c0:	fcc2                	sd	a6,120(sp)
    800062c2:	e146                	sd	a7,128(sp)
    800062c4:	e54a                	sd	s2,136(sp)
    800062c6:	e94e                	sd	s3,144(sp)
    800062c8:	ed52                	sd	s4,152(sp)
    800062ca:	f156                	sd	s5,160(sp)
    800062cc:	f55a                	sd	s6,168(sp)
    800062ce:	f95e                	sd	s7,176(sp)
    800062d0:	fd62                	sd	s8,184(sp)
    800062d2:	e1e6                	sd	s9,192(sp)
    800062d4:	e5ea                	sd	s10,200(sp)
    800062d6:	e9ee                	sd	s11,208(sp)
    800062d8:	edf2                	sd	t3,216(sp)
    800062da:	f1f6                	sd	t4,224(sp)
    800062dc:	f5fa                	sd	t5,232(sp)
    800062de:	f9fe                	sd	t6,240(sp)
    800062e0:	af1fc0ef          	jal	ra,80002dd0 <kerneltrap>
    800062e4:	6082                	ld	ra,0(sp)
    800062e6:	6122                	ld	sp,8(sp)
    800062e8:	61c2                	ld	gp,16(sp)
    800062ea:	7282                	ld	t0,32(sp)
    800062ec:	7322                	ld	t1,40(sp)
    800062ee:	73c2                	ld	t2,48(sp)
    800062f0:	7462                	ld	s0,56(sp)
    800062f2:	6486                	ld	s1,64(sp)
    800062f4:	6526                	ld	a0,72(sp)
    800062f6:	65c6                	ld	a1,80(sp)
    800062f8:	6666                	ld	a2,88(sp)
    800062fa:	7686                	ld	a3,96(sp)
    800062fc:	7726                	ld	a4,104(sp)
    800062fe:	77c6                	ld	a5,112(sp)
    80006300:	7866                	ld	a6,120(sp)
    80006302:	688a                	ld	a7,128(sp)
    80006304:	692a                	ld	s2,136(sp)
    80006306:	69ca                	ld	s3,144(sp)
    80006308:	6a6a                	ld	s4,152(sp)
    8000630a:	7a8a                	ld	s5,160(sp)
    8000630c:	7b2a                	ld	s6,168(sp)
    8000630e:	7bca                	ld	s7,176(sp)
    80006310:	7c6a                	ld	s8,184(sp)
    80006312:	6c8e                	ld	s9,192(sp)
    80006314:	6d2e                	ld	s10,200(sp)
    80006316:	6dce                	ld	s11,208(sp)
    80006318:	6e6e                	ld	t3,216(sp)
    8000631a:	7e8e                	ld	t4,224(sp)
    8000631c:	7f2e                	ld	t5,232(sp)
    8000631e:	7fce                	ld	t6,240(sp)
    80006320:	6111                	addi	sp,sp,256
    80006322:	10200073          	sret
    80006326:	00000013          	nop
    8000632a:	00000013          	nop
    8000632e:	0001                	nop

0000000080006330 <timervec>:
    80006330:	34051573          	csrrw	a0,mscratch,a0
    80006334:	e10c                	sd	a1,0(a0)
    80006336:	e510                	sd	a2,8(a0)
    80006338:	e914                	sd	a3,16(a0)
    8000633a:	6d0c                	ld	a1,24(a0)
    8000633c:	7110                	ld	a2,32(a0)
    8000633e:	6194                	ld	a3,0(a1)
    80006340:	96b2                	add	a3,a3,a2
    80006342:	e194                	sd	a3,0(a1)
    80006344:	4589                	li	a1,2
    80006346:	14459073          	csrw	sip,a1
    8000634a:	6914                	ld	a3,16(a0)
    8000634c:	6510                	ld	a2,8(a0)
    8000634e:	610c                	ld	a1,0(a0)
    80006350:	34051573          	csrrw	a0,mscratch,a0
    80006354:	30200073          	mret
	...

000000008000635a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000635a:	1141                	addi	sp,sp,-16
    8000635c:	e422                	sd	s0,8(sp)
    8000635e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006360:	0c0007b7          	lui	a5,0xc000
    80006364:	4705                	li	a4,1
    80006366:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006368:	c3d8                	sw	a4,4(a5)
}
    8000636a:	6422                	ld	s0,8(sp)
    8000636c:	0141                	addi	sp,sp,16
    8000636e:	8082                	ret

0000000080006370 <plicinithart>:

void
plicinithart(void)
{
    80006370:	1141                	addi	sp,sp,-16
    80006372:	e406                	sd	ra,8(sp)
    80006374:	e022                	sd	s0,0(sp)
    80006376:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006378:	ffffb097          	auipc	ra,0xffffb
    8000637c:	622080e7          	jalr	1570(ra) # 8000199a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006380:	0085171b          	slliw	a4,a0,0x8
    80006384:	0c0027b7          	lui	a5,0xc002
    80006388:	97ba                	add	a5,a5,a4
    8000638a:	40200713          	li	a4,1026
    8000638e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006392:	00d5151b          	slliw	a0,a0,0xd
    80006396:	0c2017b7          	lui	a5,0xc201
    8000639a:	953e                	add	a0,a0,a5
    8000639c:	00052023          	sw	zero,0(a0)
}
    800063a0:	60a2                	ld	ra,8(sp)
    800063a2:	6402                	ld	s0,0(sp)
    800063a4:	0141                	addi	sp,sp,16
    800063a6:	8082                	ret

00000000800063a8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800063a8:	1141                	addi	sp,sp,-16
    800063aa:	e406                	sd	ra,8(sp)
    800063ac:	e022                	sd	s0,0(sp)
    800063ae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800063b0:	ffffb097          	auipc	ra,0xffffb
    800063b4:	5ea080e7          	jalr	1514(ra) # 8000199a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800063b8:	00d5179b          	slliw	a5,a0,0xd
    800063bc:	0c201537          	lui	a0,0xc201
    800063c0:	953e                	add	a0,a0,a5
  return irq;
}
    800063c2:	4148                	lw	a0,4(a0)
    800063c4:	60a2                	ld	ra,8(sp)
    800063c6:	6402                	ld	s0,0(sp)
    800063c8:	0141                	addi	sp,sp,16
    800063ca:	8082                	ret

00000000800063cc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800063cc:	1101                	addi	sp,sp,-32
    800063ce:	ec06                	sd	ra,24(sp)
    800063d0:	e822                	sd	s0,16(sp)
    800063d2:	e426                	sd	s1,8(sp)
    800063d4:	1000                	addi	s0,sp,32
    800063d6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800063d8:	ffffb097          	auipc	ra,0xffffb
    800063dc:	5c2080e7          	jalr	1474(ra) # 8000199a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800063e0:	00d5151b          	slliw	a0,a0,0xd
    800063e4:	0c2017b7          	lui	a5,0xc201
    800063e8:	97aa                	add	a5,a5,a0
    800063ea:	c3c4                	sw	s1,4(a5)
}
    800063ec:	60e2                	ld	ra,24(sp)
    800063ee:	6442                	ld	s0,16(sp)
    800063f0:	64a2                	ld	s1,8(sp)
    800063f2:	6105                	addi	sp,sp,32
    800063f4:	8082                	ret

00000000800063f6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800063f6:	1141                	addi	sp,sp,-16
    800063f8:	e406                	sd	ra,8(sp)
    800063fa:	e022                	sd	s0,0(sp)
    800063fc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800063fe:	479d                	li	a5,7
    80006400:	04a7cc63          	blt	a5,a0,80006458 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006404:	0001d797          	auipc	a5,0x1d
    80006408:	acc78793          	addi	a5,a5,-1332 # 80022ed0 <disk>
    8000640c:	97aa                	add	a5,a5,a0
    8000640e:	0187c783          	lbu	a5,24(a5)
    80006412:	ebb9                	bnez	a5,80006468 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006414:	00451613          	slli	a2,a0,0x4
    80006418:	0001d797          	auipc	a5,0x1d
    8000641c:	ab878793          	addi	a5,a5,-1352 # 80022ed0 <disk>
    80006420:	6394                	ld	a3,0(a5)
    80006422:	96b2                	add	a3,a3,a2
    80006424:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006428:	6398                	ld	a4,0(a5)
    8000642a:	9732                	add	a4,a4,a2
    8000642c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006430:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006434:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006438:	953e                	add	a0,a0,a5
    8000643a:	4785                	li	a5,1
    8000643c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006440:	0001d517          	auipc	a0,0x1d
    80006444:	aa850513          	addi	a0,a0,-1368 # 80022ee8 <disk+0x18>
    80006448:	ffffc097          	auipc	ra,0xffffc
    8000644c:	0ee080e7          	jalr	238(ra) # 80002536 <wakeup>
}
    80006450:	60a2                	ld	ra,8(sp)
    80006452:	6402                	ld	s0,0(sp)
    80006454:	0141                	addi	sp,sp,16
    80006456:	8082                	ret
    panic("free_desc 1");
    80006458:	00002517          	auipc	a0,0x2
    8000645c:	43850513          	addi	a0,a0,1080 # 80008890 <syscalls+0x318>
    80006460:	ffffa097          	auipc	ra,0xffffa
    80006464:	0e4080e7          	jalr	228(ra) # 80000544 <panic>
    panic("free_desc 2");
    80006468:	00002517          	auipc	a0,0x2
    8000646c:	43850513          	addi	a0,a0,1080 # 800088a0 <syscalls+0x328>
    80006470:	ffffa097          	auipc	ra,0xffffa
    80006474:	0d4080e7          	jalr	212(ra) # 80000544 <panic>

0000000080006478 <virtio_disk_init>:
{
    80006478:	1101                	addi	sp,sp,-32
    8000647a:	ec06                	sd	ra,24(sp)
    8000647c:	e822                	sd	s0,16(sp)
    8000647e:	e426                	sd	s1,8(sp)
    80006480:	e04a                	sd	s2,0(sp)
    80006482:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006484:	00002597          	auipc	a1,0x2
    80006488:	42c58593          	addi	a1,a1,1068 # 800088b0 <syscalls+0x338>
    8000648c:	0001d517          	auipc	a0,0x1d
    80006490:	b6c50513          	addi	a0,a0,-1172 # 80022ff8 <disk+0x128>
    80006494:	ffffa097          	auipc	ra,0xffffa
    80006498:	6c6080e7          	jalr	1734(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000649c:	100017b7          	lui	a5,0x10001
    800064a0:	4398                	lw	a4,0(a5)
    800064a2:	2701                	sext.w	a4,a4
    800064a4:	747277b7          	lui	a5,0x74727
    800064a8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800064ac:	14f71e63          	bne	a4,a5,80006608 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800064b0:	100017b7          	lui	a5,0x10001
    800064b4:	43dc                	lw	a5,4(a5)
    800064b6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064b8:	4709                	li	a4,2
    800064ba:	14e79763          	bne	a5,a4,80006608 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064be:	100017b7          	lui	a5,0x10001
    800064c2:	479c                	lw	a5,8(a5)
    800064c4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800064c6:	14e79163          	bne	a5,a4,80006608 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800064ca:	100017b7          	lui	a5,0x10001
    800064ce:	47d8                	lw	a4,12(a5)
    800064d0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064d2:	554d47b7          	lui	a5,0x554d4
    800064d6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800064da:	12f71763          	bne	a4,a5,80006608 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    800064de:	100017b7          	lui	a5,0x10001
    800064e2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800064e6:	4705                	li	a4,1
    800064e8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800064ea:	470d                	li	a4,3
    800064ec:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800064ee:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800064f0:	c7ffe737          	lui	a4,0xc7ffe
    800064f4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdb74f>
    800064f8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800064fa:	2701                	sext.w	a4,a4
    800064fc:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800064fe:	472d                	li	a4,11
    80006500:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006502:	0707a903          	lw	s2,112(a5)
    80006506:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006508:	00897793          	andi	a5,s2,8
    8000650c:	10078663          	beqz	a5,80006618 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006510:	100017b7          	lui	a5,0x10001
    80006514:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006518:	43fc                	lw	a5,68(a5)
    8000651a:	2781                	sext.w	a5,a5
    8000651c:	10079663          	bnez	a5,80006628 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006520:	100017b7          	lui	a5,0x10001
    80006524:	5bdc                	lw	a5,52(a5)
    80006526:	2781                	sext.w	a5,a5
  if(max == 0)
    80006528:	10078863          	beqz	a5,80006638 <virtio_disk_init+0x1c0>
  if(max < NUM)
    8000652c:	471d                	li	a4,7
    8000652e:	10f77d63          	bgeu	a4,a5,80006648 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80006532:	ffffa097          	auipc	ra,0xffffa
    80006536:	5c8080e7          	jalr	1480(ra) # 80000afa <kalloc>
    8000653a:	0001d497          	auipc	s1,0x1d
    8000653e:	99648493          	addi	s1,s1,-1642 # 80022ed0 <disk>
    80006542:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006544:	ffffa097          	auipc	ra,0xffffa
    80006548:	5b6080e7          	jalr	1462(ra) # 80000afa <kalloc>
    8000654c:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000654e:	ffffa097          	auipc	ra,0xffffa
    80006552:	5ac080e7          	jalr	1452(ra) # 80000afa <kalloc>
    80006556:	87aa                	mv	a5,a0
    80006558:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    8000655a:	6088                	ld	a0,0(s1)
    8000655c:	cd75                	beqz	a0,80006658 <virtio_disk_init+0x1e0>
    8000655e:	0001d717          	auipc	a4,0x1d
    80006562:	97a73703          	ld	a4,-1670(a4) # 80022ed8 <disk+0x8>
    80006566:	cb6d                	beqz	a4,80006658 <virtio_disk_init+0x1e0>
    80006568:	cbe5                	beqz	a5,80006658 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    8000656a:	6605                	lui	a2,0x1
    8000656c:	4581                	li	a1,0
    8000656e:	ffffa097          	auipc	ra,0xffffa
    80006572:	778080e7          	jalr	1912(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006576:	0001d497          	auipc	s1,0x1d
    8000657a:	95a48493          	addi	s1,s1,-1702 # 80022ed0 <disk>
    8000657e:	6605                	lui	a2,0x1
    80006580:	4581                	li	a1,0
    80006582:	6488                	ld	a0,8(s1)
    80006584:	ffffa097          	auipc	ra,0xffffa
    80006588:	762080e7          	jalr	1890(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    8000658c:	6605                	lui	a2,0x1
    8000658e:	4581                	li	a1,0
    80006590:	6888                	ld	a0,16(s1)
    80006592:	ffffa097          	auipc	ra,0xffffa
    80006596:	754080e7          	jalr	1876(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000659a:	100017b7          	lui	a5,0x10001
    8000659e:	4721                	li	a4,8
    800065a0:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800065a2:	4098                	lw	a4,0(s1)
    800065a4:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800065a8:	40d8                	lw	a4,4(s1)
    800065aa:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800065ae:	6498                	ld	a4,8(s1)
    800065b0:	0007069b          	sext.w	a3,a4
    800065b4:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800065b8:	9701                	srai	a4,a4,0x20
    800065ba:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800065be:	6898                	ld	a4,16(s1)
    800065c0:	0007069b          	sext.w	a3,a4
    800065c4:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800065c8:	9701                	srai	a4,a4,0x20
    800065ca:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800065ce:	4685                	li	a3,1
    800065d0:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    800065d2:	4705                	li	a4,1
    800065d4:	00d48c23          	sb	a3,24(s1)
    800065d8:	00e48ca3          	sb	a4,25(s1)
    800065dc:	00e48d23          	sb	a4,26(s1)
    800065e0:	00e48da3          	sb	a4,27(s1)
    800065e4:	00e48e23          	sb	a4,28(s1)
    800065e8:	00e48ea3          	sb	a4,29(s1)
    800065ec:	00e48f23          	sb	a4,30(s1)
    800065f0:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800065f4:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800065f8:	0727a823          	sw	s2,112(a5)
}
    800065fc:	60e2                	ld	ra,24(sp)
    800065fe:	6442                	ld	s0,16(sp)
    80006600:	64a2                	ld	s1,8(sp)
    80006602:	6902                	ld	s2,0(sp)
    80006604:	6105                	addi	sp,sp,32
    80006606:	8082                	ret
    panic("could not find virtio disk");
    80006608:	00002517          	auipc	a0,0x2
    8000660c:	2b850513          	addi	a0,a0,696 # 800088c0 <syscalls+0x348>
    80006610:	ffffa097          	auipc	ra,0xffffa
    80006614:	f34080e7          	jalr	-204(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006618:	00002517          	auipc	a0,0x2
    8000661c:	2c850513          	addi	a0,a0,712 # 800088e0 <syscalls+0x368>
    80006620:	ffffa097          	auipc	ra,0xffffa
    80006624:	f24080e7          	jalr	-220(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80006628:	00002517          	auipc	a0,0x2
    8000662c:	2d850513          	addi	a0,a0,728 # 80008900 <syscalls+0x388>
    80006630:	ffffa097          	auipc	ra,0xffffa
    80006634:	f14080e7          	jalr	-236(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80006638:	00002517          	auipc	a0,0x2
    8000663c:	2e850513          	addi	a0,a0,744 # 80008920 <syscalls+0x3a8>
    80006640:	ffffa097          	auipc	ra,0xffffa
    80006644:	f04080e7          	jalr	-252(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    80006648:	00002517          	auipc	a0,0x2
    8000664c:	2f850513          	addi	a0,a0,760 # 80008940 <syscalls+0x3c8>
    80006650:	ffffa097          	auipc	ra,0xffffa
    80006654:	ef4080e7          	jalr	-268(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    80006658:	00002517          	auipc	a0,0x2
    8000665c:	30850513          	addi	a0,a0,776 # 80008960 <syscalls+0x3e8>
    80006660:	ffffa097          	auipc	ra,0xffffa
    80006664:	ee4080e7          	jalr	-284(ra) # 80000544 <panic>

0000000080006668 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006668:	7159                	addi	sp,sp,-112
    8000666a:	f486                	sd	ra,104(sp)
    8000666c:	f0a2                	sd	s0,96(sp)
    8000666e:	eca6                	sd	s1,88(sp)
    80006670:	e8ca                	sd	s2,80(sp)
    80006672:	e4ce                	sd	s3,72(sp)
    80006674:	e0d2                	sd	s4,64(sp)
    80006676:	fc56                	sd	s5,56(sp)
    80006678:	f85a                	sd	s6,48(sp)
    8000667a:	f45e                	sd	s7,40(sp)
    8000667c:	f062                	sd	s8,32(sp)
    8000667e:	ec66                	sd	s9,24(sp)
    80006680:	e86a                	sd	s10,16(sp)
    80006682:	1880                	addi	s0,sp,112
    80006684:	892a                	mv	s2,a0
    80006686:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006688:	00c52c83          	lw	s9,12(a0)
    8000668c:	001c9c9b          	slliw	s9,s9,0x1
    80006690:	1c82                	slli	s9,s9,0x20
    80006692:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006696:	0001d517          	auipc	a0,0x1d
    8000669a:	96250513          	addi	a0,a0,-1694 # 80022ff8 <disk+0x128>
    8000669e:	ffffa097          	auipc	ra,0xffffa
    800066a2:	54c080e7          	jalr	1356(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    800066a6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800066a8:	4ba1                	li	s7,8
      disk.free[i] = 0;
    800066aa:	0001db17          	auipc	s6,0x1d
    800066ae:	826b0b13          	addi	s6,s6,-2010 # 80022ed0 <disk>
  for(int i = 0; i < 3; i++){
    800066b2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800066b4:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800066b6:	0001dc17          	auipc	s8,0x1d
    800066ba:	942c0c13          	addi	s8,s8,-1726 # 80022ff8 <disk+0x128>
    800066be:	a8b5                	j	8000673a <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    800066c0:	00fb06b3          	add	a3,s6,a5
    800066c4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800066c8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800066ca:	0207c563          	bltz	a5,800066f4 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800066ce:	2485                	addiw	s1,s1,1
    800066d0:	0711                	addi	a4,a4,4
    800066d2:	1f548a63          	beq	s1,s5,800068c6 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    800066d6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800066d8:	0001c697          	auipc	a3,0x1c
    800066dc:	7f868693          	addi	a3,a3,2040 # 80022ed0 <disk>
    800066e0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800066e2:	0186c583          	lbu	a1,24(a3)
    800066e6:	fde9                	bnez	a1,800066c0 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800066e8:	2785                	addiw	a5,a5,1
    800066ea:	0685                	addi	a3,a3,1
    800066ec:	ff779be3          	bne	a5,s7,800066e2 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800066f0:	57fd                	li	a5,-1
    800066f2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800066f4:	02905a63          	blez	s1,80006728 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800066f8:	f9042503          	lw	a0,-112(s0)
    800066fc:	00000097          	auipc	ra,0x0
    80006700:	cfa080e7          	jalr	-774(ra) # 800063f6 <free_desc>
      for(int j = 0; j < i; j++)
    80006704:	4785                	li	a5,1
    80006706:	0297d163          	bge	a5,s1,80006728 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000670a:	f9442503          	lw	a0,-108(s0)
    8000670e:	00000097          	auipc	ra,0x0
    80006712:	ce8080e7          	jalr	-792(ra) # 800063f6 <free_desc>
      for(int j = 0; j < i; j++)
    80006716:	4789                	li	a5,2
    80006718:	0097d863          	bge	a5,s1,80006728 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000671c:	f9842503          	lw	a0,-104(s0)
    80006720:	00000097          	auipc	ra,0x0
    80006724:	cd6080e7          	jalr	-810(ra) # 800063f6 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006728:	85e2                	mv	a1,s8
    8000672a:	0001c517          	auipc	a0,0x1c
    8000672e:	7be50513          	addi	a0,a0,1982 # 80022ee8 <disk+0x18>
    80006732:	ffffc097          	auipc	ra,0xffffc
    80006736:	c54080e7          	jalr	-940(ra) # 80002386 <sleep>
  for(int i = 0; i < 3; i++){
    8000673a:	f9040713          	addi	a4,s0,-112
    8000673e:	84ce                	mv	s1,s3
    80006740:	bf59                	j	800066d6 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006742:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    80006746:	00479693          	slli	a3,a5,0x4
    8000674a:	0001c797          	auipc	a5,0x1c
    8000674e:	78678793          	addi	a5,a5,1926 # 80022ed0 <disk>
    80006752:	97b6                	add	a5,a5,a3
    80006754:	4685                	li	a3,1
    80006756:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006758:	0001c597          	auipc	a1,0x1c
    8000675c:	77858593          	addi	a1,a1,1912 # 80022ed0 <disk>
    80006760:	00a60793          	addi	a5,a2,10
    80006764:	0792                	slli	a5,a5,0x4
    80006766:	97ae                	add	a5,a5,a1
    80006768:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    8000676c:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006770:	f6070693          	addi	a3,a4,-160
    80006774:	619c                	ld	a5,0(a1)
    80006776:	97b6                	add	a5,a5,a3
    80006778:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000677a:	6188                	ld	a0,0(a1)
    8000677c:	96aa                	add	a3,a3,a0
    8000677e:	47c1                	li	a5,16
    80006780:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006782:	4785                	li	a5,1
    80006784:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006788:	f9442783          	lw	a5,-108(s0)
    8000678c:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006790:	0792                	slli	a5,a5,0x4
    80006792:	953e                	add	a0,a0,a5
    80006794:	05890693          	addi	a3,s2,88
    80006798:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000679a:	6188                	ld	a0,0(a1)
    8000679c:	97aa                	add	a5,a5,a0
    8000679e:	40000693          	li	a3,1024
    800067a2:	c794                	sw	a3,8(a5)
  if(write)
    800067a4:	100d0d63          	beqz	s10,800068be <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800067a8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800067ac:	00c7d683          	lhu	a3,12(a5)
    800067b0:	0016e693          	ori	a3,a3,1
    800067b4:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    800067b8:	f9842583          	lw	a1,-104(s0)
    800067bc:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800067c0:	0001c697          	auipc	a3,0x1c
    800067c4:	71068693          	addi	a3,a3,1808 # 80022ed0 <disk>
    800067c8:	00260793          	addi	a5,a2,2
    800067cc:	0792                	slli	a5,a5,0x4
    800067ce:	97b6                	add	a5,a5,a3
    800067d0:	587d                	li	a6,-1
    800067d2:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800067d6:	0592                	slli	a1,a1,0x4
    800067d8:	952e                	add	a0,a0,a1
    800067da:	f9070713          	addi	a4,a4,-112
    800067de:	9736                	add	a4,a4,a3
    800067e0:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    800067e2:	6298                	ld	a4,0(a3)
    800067e4:	972e                	add	a4,a4,a1
    800067e6:	4585                	li	a1,1
    800067e8:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800067ea:	4509                	li	a0,2
    800067ec:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    800067f0:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800067f4:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800067f8:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800067fc:	6698                	ld	a4,8(a3)
    800067fe:	00275783          	lhu	a5,2(a4)
    80006802:	8b9d                	andi	a5,a5,7
    80006804:	0786                	slli	a5,a5,0x1
    80006806:	97ba                	add	a5,a5,a4
    80006808:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    8000680c:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006810:	6698                	ld	a4,8(a3)
    80006812:	00275783          	lhu	a5,2(a4)
    80006816:	2785                	addiw	a5,a5,1
    80006818:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    8000681c:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006820:	100017b7          	lui	a5,0x10001
    80006824:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006828:	00492703          	lw	a4,4(s2)
    8000682c:	4785                	li	a5,1
    8000682e:	02f71163          	bne	a4,a5,80006850 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    80006832:	0001c997          	auipc	s3,0x1c
    80006836:	7c698993          	addi	s3,s3,1990 # 80022ff8 <disk+0x128>
  while(b->disk == 1) {
    8000683a:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000683c:	85ce                	mv	a1,s3
    8000683e:	854a                	mv	a0,s2
    80006840:	ffffc097          	auipc	ra,0xffffc
    80006844:	b46080e7          	jalr	-1210(ra) # 80002386 <sleep>
  while(b->disk == 1) {
    80006848:	00492783          	lw	a5,4(s2)
    8000684c:	fe9788e3          	beq	a5,s1,8000683c <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    80006850:	f9042903          	lw	s2,-112(s0)
    80006854:	00290793          	addi	a5,s2,2
    80006858:	00479713          	slli	a4,a5,0x4
    8000685c:	0001c797          	auipc	a5,0x1c
    80006860:	67478793          	addi	a5,a5,1652 # 80022ed0 <disk>
    80006864:	97ba                	add	a5,a5,a4
    80006866:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000686a:	0001c997          	auipc	s3,0x1c
    8000686e:	66698993          	addi	s3,s3,1638 # 80022ed0 <disk>
    80006872:	00491713          	slli	a4,s2,0x4
    80006876:	0009b783          	ld	a5,0(s3)
    8000687a:	97ba                	add	a5,a5,a4
    8000687c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006880:	854a                	mv	a0,s2
    80006882:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006886:	00000097          	auipc	ra,0x0
    8000688a:	b70080e7          	jalr	-1168(ra) # 800063f6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000688e:	8885                	andi	s1,s1,1
    80006890:	f0ed                	bnez	s1,80006872 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006892:	0001c517          	auipc	a0,0x1c
    80006896:	76650513          	addi	a0,a0,1894 # 80022ff8 <disk+0x128>
    8000689a:	ffffa097          	auipc	ra,0xffffa
    8000689e:	404080e7          	jalr	1028(ra) # 80000c9e <release>
}
    800068a2:	70a6                	ld	ra,104(sp)
    800068a4:	7406                	ld	s0,96(sp)
    800068a6:	64e6                	ld	s1,88(sp)
    800068a8:	6946                	ld	s2,80(sp)
    800068aa:	69a6                	ld	s3,72(sp)
    800068ac:	6a06                	ld	s4,64(sp)
    800068ae:	7ae2                	ld	s5,56(sp)
    800068b0:	7b42                	ld	s6,48(sp)
    800068b2:	7ba2                	ld	s7,40(sp)
    800068b4:	7c02                	ld	s8,32(sp)
    800068b6:	6ce2                	ld	s9,24(sp)
    800068b8:	6d42                	ld	s10,16(sp)
    800068ba:	6165                	addi	sp,sp,112
    800068bc:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800068be:	4689                	li	a3,2
    800068c0:	00d79623          	sh	a3,12(a5)
    800068c4:	b5e5                	j	800067ac <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800068c6:	f9042603          	lw	a2,-112(s0)
    800068ca:	00a60713          	addi	a4,a2,10
    800068ce:	0712                	slli	a4,a4,0x4
    800068d0:	0001c517          	auipc	a0,0x1c
    800068d4:	60850513          	addi	a0,a0,1544 # 80022ed8 <disk+0x8>
    800068d8:	953a                	add	a0,a0,a4
  if(write)
    800068da:	e60d14e3          	bnez	s10,80006742 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800068de:	00a60793          	addi	a5,a2,10
    800068e2:	00479693          	slli	a3,a5,0x4
    800068e6:	0001c797          	auipc	a5,0x1c
    800068ea:	5ea78793          	addi	a5,a5,1514 # 80022ed0 <disk>
    800068ee:	97b6                	add	a5,a5,a3
    800068f0:	0007a423          	sw	zero,8(a5)
    800068f4:	b595                	j	80006758 <virtio_disk_rw+0xf0>

00000000800068f6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800068f6:	1101                	addi	sp,sp,-32
    800068f8:	ec06                	sd	ra,24(sp)
    800068fa:	e822                	sd	s0,16(sp)
    800068fc:	e426                	sd	s1,8(sp)
    800068fe:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006900:	0001c497          	auipc	s1,0x1c
    80006904:	5d048493          	addi	s1,s1,1488 # 80022ed0 <disk>
    80006908:	0001c517          	auipc	a0,0x1c
    8000690c:	6f050513          	addi	a0,a0,1776 # 80022ff8 <disk+0x128>
    80006910:	ffffa097          	auipc	ra,0xffffa
    80006914:	2da080e7          	jalr	730(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006918:	10001737          	lui	a4,0x10001
    8000691c:	533c                	lw	a5,96(a4)
    8000691e:	8b8d                	andi	a5,a5,3
    80006920:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006922:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006926:	689c                	ld	a5,16(s1)
    80006928:	0204d703          	lhu	a4,32(s1)
    8000692c:	0027d783          	lhu	a5,2(a5)
    80006930:	04f70863          	beq	a4,a5,80006980 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006934:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006938:	6898                	ld	a4,16(s1)
    8000693a:	0204d783          	lhu	a5,32(s1)
    8000693e:	8b9d                	andi	a5,a5,7
    80006940:	078e                	slli	a5,a5,0x3
    80006942:	97ba                	add	a5,a5,a4
    80006944:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006946:	00278713          	addi	a4,a5,2
    8000694a:	0712                	slli	a4,a4,0x4
    8000694c:	9726                	add	a4,a4,s1
    8000694e:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006952:	e721                	bnez	a4,8000699a <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006954:	0789                	addi	a5,a5,2
    80006956:	0792                	slli	a5,a5,0x4
    80006958:	97a6                	add	a5,a5,s1
    8000695a:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000695c:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006960:	ffffc097          	auipc	ra,0xffffc
    80006964:	bd6080e7          	jalr	-1066(ra) # 80002536 <wakeup>

    disk.used_idx += 1;
    80006968:	0204d783          	lhu	a5,32(s1)
    8000696c:	2785                	addiw	a5,a5,1
    8000696e:	17c2                	slli	a5,a5,0x30
    80006970:	93c1                	srli	a5,a5,0x30
    80006972:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006976:	6898                	ld	a4,16(s1)
    80006978:	00275703          	lhu	a4,2(a4)
    8000697c:	faf71ce3          	bne	a4,a5,80006934 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006980:	0001c517          	auipc	a0,0x1c
    80006984:	67850513          	addi	a0,a0,1656 # 80022ff8 <disk+0x128>
    80006988:	ffffa097          	auipc	ra,0xffffa
    8000698c:	316080e7          	jalr	790(ra) # 80000c9e <release>
}
    80006990:	60e2                	ld	ra,24(sp)
    80006992:	6442                	ld	s0,16(sp)
    80006994:	64a2                	ld	s1,8(sp)
    80006996:	6105                	addi	sp,sp,32
    80006998:	8082                	ret
      panic("virtio_disk_intr status");
    8000699a:	00002517          	auipc	a0,0x2
    8000699e:	fde50513          	addi	a0,a0,-34 # 80008978 <syscalls+0x400>
    800069a2:	ffffa097          	auipc	ra,0xffffa
    800069a6:	ba2080e7          	jalr	-1118(ra) # 80000544 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
