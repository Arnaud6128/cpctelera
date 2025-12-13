; Untitled, Song part, encoded in the AKM (minimalist) format V0.


	dw Untitled_InstrumentIndexes	; Index table for the Instruments.
	dw 0	; Index table for the Arpeggios.
	dw 0	; Index table for the Pitches.

; The subsongs references.
	dw Untitled_Subsong0

; The Instrument indexes.
Untitled_InstrumentIndexes
	dw Untitled_Instrument0
	dw Untitled_Instrument1
	dw Untitled_Instrument2
	dw Untitled_Instrument3
	dw Untitled_Instrument4
	dw Untitled_Instrument5
	dw Untitled_Instrument6
	dw Untitled_Instrument7
	dw Untitled_Instrument8
	dw Untitled_Instrument9
	dw Untitled_Instrument10
	dw Untitled_Instrument11
	dw Untitled_Instrument12
	dw Untitled_Instrument13
	dw Untitled_Instrument14
	dw Untitled_Instrument15

; The Instrument.
Untitled_Instrument0
	db 255	; Speed.

Untitled_Instrument0Loop	db 0	; Volume: 0.

	db 4	; End the instrument.
	dw Untitled_Instrument0Loop	; Loops.

Untitled_Instrument1
	db 0	; Speed.

	db 185	; Volume: 14.
	db 24	; Arpeggio: 12.

	db 185	; Volume: 14.
	db 24	; Arpeggio: 12.

	db 53	; Volume: 13.

	db 181	; Volume: 13.
	db 24	; Arpeggio: 12.

	db 49	; Volume: 12.

	db 177	; Volume: 12.
	db 24	; Arpeggio: 12.

	db 173	; Volume: 11.
	db 24	; Arpeggio: 12.

	db 41	; Volume: 10.

	db 165	; Volume: 9.
	db 24	; Arpeggio: 12.

	db 33	; Volume: 8.

	db 157	; Volume: 7.
	db 24	; Arpeggio: 12.

	db 153	; Volume: 6.
	db 24	; Arpeggio: 12.

	db 21	; Volume: 5.

	db 149	; Volume: 5.
	db 24	; Arpeggio: 12.

	db 17	; Volume: 4.

	db 141	; Volume: 3.
	db 24	; Arpeggio: 12.

	db 137	; Volume: 2.
	db 24	; Arpeggio: 12.

	db 5	; Volume: 1.

	db 0	; Volume: 0.

	db 4	; End the instrument.
	dw Untitled_Instrument0Loop	; Loop to silence.

Untitled_Instrument2
	db 0	; Speed.

	db 185	; Volume: 14.
	db 48	; Arpeggio: 24.

	db 57	; Volume: 14.

	db 181	; Volume: 13.
	db 24	; Arpeggio: 12.

	db 181	; Volume: 13.
	db 24	; Arpeggio: 12.

	db 49	; Volume: 12.

	db 177	; Volume: 12.
	db 48	; Arpeggio: 24.

	db 45	; Volume: 11.

	db 169	; Volume: 10.
	db 24	; Arpeggio: 12.

	db 165	; Volume: 9.
	db 48	; Arpeggio: 24.

	db 33	; Volume: 8.

	db 157	; Volume: 7.
	db 24	; Arpeggio: 12.

	db 153	; Volume: 6.
	db 24	; Arpeggio: 12.

	db 21	; Volume: 5.

	db 149	; Volume: 5.
	db 48	; Arpeggio: 24.

	db 17	; Volume: 4.

	db 141	; Volume: 3.
	db 24	; Arpeggio: 12.

	db 137	; Volume: 2.
	db 48	; Arpeggio: 24.

	db 5	; Volume: 1.

	db 0	; Volume: 0.

	db 4	; End the instrument.
	dw Untitled_Instrument0Loop	; Loop to silence.

Untitled_Instrument3
	db 0	; Speed.

	db 61	; Volume: 15.

	db 21	; Volume: 5.

	db 4	; End the instrument.
	dw Untitled_Instrument0Loop	; Loop to silence.

Untitled_Instrument4
	db 0	; Speed.

	db 189	; Volume: 15.
	db 1	; Arpeggio: 0.
	db 1	; Noise: 1.

	db 149	; Volume: 5.
	db 1	; Arpeggio: 0.
	db 1	; Noise: 1.

	db 0	; Volume: 0.

	db 0	; Volume: 0.

	db 169	; Volume: 10.
	db 1	; Arpeggio: 0.
	db 1	; Noise: 1.

	db 141	; Volume: 3.
	db 1	; Arpeggio: 0.
	db 1	; Noise: 1.

	db 4	; End the instrument.
	dw Untitled_Instrument0Loop	; Loop to silence.

Untitled_Instrument5
	db 0	; Speed.

	db 61	; Volume: 15.

	db 33	; Volume: 8.

	db 25	; Volume: 6.

	db 21	; Volume: 5.

	db 177	; Volume: 12.
	db 24	; Arpeggio: 12.

	db 37	; Volume: 9.

	db 33	; Volume: 8.

	db 25	; Volume: 6.

	db 4	; End the instrument.
	dw Untitled_Instrument0Loop	; Loop to silence.

Untitled_Instrument6
	db 0	; Speed.

	db 248	; Volume: 15.
	db 1	; Noise.

	db 240	; Volume: 14.
	db 1	; Noise.

	db 232	; Volume: 13.
	db 1	; Noise.

	db 224	; Volume: 12.
	db 1	; Noise.

	db 216	; Volume: 11.
	db 1	; Noise.

	db 208	; Volume: 10.
	db 1	; Noise.

	db 200	; Volume: 9.
	db 1	; Noise.

	db 192	; Volume: 8.
	db 1	; Noise.

	db 184	; Volume: 7.
	db 1	; Noise.

	db 176	; Volume: 6.
	db 1	; Noise.

	db 168	; Volume: 5.
	db 1	; Noise.

	db 160	; Volume: 4.
	db 1	; Noise.

	db 152	; Volume: 3.
	db 1	; Noise.

	db 144	; Volume: 2.
	db 1	; Noise.

	db 136	; Volume: 1.
	db 1	; Noise.

	db 4	; End the instrument.
	dw Untitled_Instrument0Loop	; Loop to silence.

Untitled_Instrument7
	db 0	; Speed.

	db 248	; Volume: 15.
	db 1	; Noise.

	db 185	; Volume: 14.
	db 1	; Arpeggio: 0.
	db 1	; Noise: 1.

	db 53	; Volume: 13.

	db 185	; Volume: 14.
	db 24	; Arpeggio: 12.

	db 53	; Volume: 13.

	db 181	; Volume: 13.
	db 48	; Arpeggio: 24.

	db 49	; Volume: 12.

	db 173	; Volume: 11.
	db 24	; Arpeggio: 12.

	db 169	; Volume: 10.
	db 48	; Arpeggio: 24.

	db 37	; Volume: 9.

	db 161	; Volume: 8.
	db 24	; Arpeggio: 12.

	db 157	; Volume: 7.
	db 24	; Arpeggio: 12.

	db 25	; Volume: 6.

	db 153	; Volume: 6.
	db 48	; Arpeggio: 24.

	db 21	; Volume: 5.

	db 145	; Volume: 4.
	db 24	; Arpeggio: 12.

	db 141	; Volume: 3.
	db 48	; Arpeggio: 24.

	db 9	; Volume: 2.

	db 133	; Volume: 1.
	db 24	; Arpeggio: 12.

	db 4	; End the instrument.
	dw Untitled_Instrument0Loop	; Loop to silence.

Untitled_Instrument8
	db 0	; Speed.

	db 41	; Volume: 10.

	db 157	; Volume: 7.
	db 232	; Arpeggio: -12.

	db 4	; End the instrument.
	dw Untitled_Instrument0Loop	; Loop to silence.

Untitled_Instrument9
	db 0	; Speed.

	db 189	; Volume: 15.
	db 233	; Arpeggio: -12.
	db 1	; Noise: 1.

	db 189	; Volume: 15.
	db 232	; Arpeggio: -12.

	db 185	; Volume: 14.
	db 232	; Arpeggio: -12.

	db 57	; Volume: 14.

	db 53	; Volume: 13.

	db 49	; Volume: 12.

	db 45	; Volume: 11.

	db 41	; Volume: 10.

	db 37	; Volume: 9.

	db 33	; Volume: 8.

	db 29	; Volume: 7.

	db 25	; Volume: 6.

	db 21	; Volume: 5.

	db 17	; Volume: 4.

	db 13	; Volume: 3.

	db 4	; End the instrument.
	dw Untitled_Instrument0Loop	; Loop to silence.

Untitled_Instrument10
	db 0	; Speed.

	db 189	; Volume: 15.
	db 24	; Arpeggio: 12.

	db 17	; Volume: 4.

	db 57	; Volume: 14.

	db 17	; Volume: 4.

	db 49	; Volume: 12.

	db 17	; Volume: 4.

	db 41	; Volume: 10.

	db 13	; Volume: 3.

	db 33	; Volume: 8.

	db 29	; Volume: 7.

	db 25	; Volume: 6.

	db 21	; Volume: 5.

	db 17	; Volume: 4.

	db 13	; Volume: 3.

	db 9	; Volume: 2.

	db 5	; Volume: 1.

	db 4	; End the instrument.
	dw Untitled_Instrument0Loop	; Loop to silence.

Untitled_Instrument11
	db 0	; Speed.

Untitled_Instrument11Loop	db 61	; Volume: 15.

	db 4	; End the instrument.
	dw Untitled_Instrument11Loop	; Loops.

Untitled_Instrument12
	db 0	; Speed.

	db 248	; Volume: 15.
	db 1	; Noise.

	db 232	; Volume: 13.
	db 1	; Noise.

	db 232	; Volume: 13.
	db 1	; Noise.

	db 224	; Volume: 12.
	db 1	; Noise.

	db 208	; Volume: 10.
	db 1	; Noise.

	db 192	; Volume: 8.
	db 1	; Noise.

	db 176	; Volume: 6.
	db 1	; Noise.

	db 168	; Volume: 5.
	db 1	; Noise.

	db 152	; Volume: 3.
	db 1	; Noise.

	db 144	; Volume: 2.
	db 1	; Noise.

	db 4	; End the instrument.
	dw Untitled_Instrument0Loop	; Loop to silence.

Untitled_Instrument13
	db 0	; Speed.

	db 61	; Volume: 15.

	db 185	; Volume: 14.
	db 8	; Arpeggio: 4.

	db 181	; Volume: 13.
	db 14	; Arpeggio: 7.

	db 49	; Volume: 12.

	db 173	; Volume: 11.
	db 8	; Arpeggio: 4.

	db 169	; Volume: 10.
	db 14	; Arpeggio: 7.

	db 37	; Volume: 9.

	db 161	; Volume: 8.
	db 8	; Arpeggio: 4.

	db 157	; Volume: 7.
	db 14	; Arpeggio: 7.

	db 25	; Volume: 6.

	db 149	; Volume: 5.
	db 8	; Arpeggio: 4.

	db 145	; Volume: 4.
	db 14	; Arpeggio: 7.

	db 13	; Volume: 3.

	db 137	; Volume: 2.
	db 8	; Arpeggio: 4.

	db 133	; Volume: 1.
	db 14	; Arpeggio: 7.

	db 4	; End the instrument.
	dw Untitled_Instrument0Loop	; Loop to silence.

Untitled_Instrument14
	db 0	; Speed.

	db 61	; Volume: 15.

	db 185	; Volume: 14.
	db 10	; Arpeggio: 5.

	db 181	; Volume: 13.
	db 20	; Arpeggio: 10.

	db 49	; Volume: 12.

	db 173	; Volume: 11.
	db 10	; Arpeggio: 5.

	db 169	; Volume: 10.
	db 20	; Arpeggio: 10.

	db 37	; Volume: 9.

	db 161	; Volume: 8.
	db 10	; Arpeggio: 5.

	db 157	; Volume: 7.
	db 20	; Arpeggio: 10.

	db 25	; Volume: 6.

	db 149	; Volume: 5.
	db 10	; Arpeggio: 5.

	db 145	; Volume: 4.
	db 20	; Arpeggio: 10.

	db 13	; Volume: 3.

	db 137	; Volume: 2.
	db 10	; Arpeggio: 5.

	db 133	; Volume: 1.
	db 20	; Arpeggio: 10.

	db 4	; End the instrument.
	dw Untitled_Instrument0Loop	; Loop to silence.

Untitled_Instrument15
	db 0	; Speed.

	db 61	; Volume: 15.

	db 185	; Volume: 14.
	db 10	; Arpeggio: 5.

	db 181	; Volume: 13.
	db 18	; Arpeggio: 9.

	db 49	; Volume: 12.

	db 173	; Volume: 11.
	db 10	; Arpeggio: 5.

	db 169	; Volume: 10.
	db 18	; Arpeggio: 9.

	db 37	; Volume: 9.

	db 161	; Volume: 8.
	db 10	; Arpeggio: 5.

	db 157	; Volume: 7.
	db 18	; Arpeggio: 9.

	db 25	; Volume: 6.

	db 149	; Volume: 5.
	db 10	; Arpeggio: 5.

	db 145	; Volume: 4.
	db 18	; Arpeggio: 9.

	db 13	; Volume: 3.

	db 137	; Volume: 2.
	db 10	; Arpeggio: 5.

	db 133	; Volume: 1.
	db 18	; Arpeggio: 9.

	db 4	; End the instrument.
	dw Untitled_Instrument0Loop	; Loop to silence.

Untitled_ArpeggioIndexes


Untitled_PitchIndexes


; Untitled, Subsong 0.
; ----------------------------------

Untitled_Subsong0
	dw Untitled_Subsong0_NoteIndexes	; Index table for the notes.
	dw Untitled_Subsong0_TrackIndexes	; Index table for the Tracks.

	db 4	; Initial speed.

	db 8	; Most used instrument.
	db 2	; Second most used instrument.

	db 0	; Most used wait.
	db 1	; Second most used wait.

	db 24	; Default start note in tracks.
	db 1	; Default start instrument in tracks.
	db 0	; Default start wait in tracks.

	db 12	; Are there effects? 12 if yes, 13 if not. Don't ask.

; The Linker.
; Pattern 0
Untitled_Subsong0_Loop
	db 250	; State byte.
	db 31	; New height.
	db 128	; New track (0) for channel 1, as a reference (index 0).
	db 0	; New transposition on channel 2.
	db ((Untitled_Subsong0_Track1 - ($ + 2)) & #ff00) / 256	; New track (1) for channel 2, as an offset. Offset MSB, then LSB.
	db ((Untitled_Subsong0_Track1 - ($ + 1)) & 255)
	db 0	; New transposition on channel 3.
	db 133	; New track (2) for channel 3, as a reference (index 5).

; Pattern 1
	db 0	; State byte.

; Pattern 2
	db 32	; State byte.
	db ((Untitled_Subsong0_Track12 - ($ + 2)) & #ff00) / 256	; New track (12) for channel 2, as an offset. Offset MSB, then LSB.
	db ((Untitled_Subsong0_Track12 - ($ + 1)) & 255)

; Pattern 3
	db 2	; State byte.
	db 15	; New height.

; Pattern 4
	db 172	; State byte.
	db 2	; New transposition on channel 1.
	db 134	; New track (14) for channel 1, as a reference (index 6).
	db ((Untitled_Subsong0_Track15 - ($ + 2)) & #ff00) / 256	; New track (15) for channel 2, as an offset. Offset MSB, then LSB.
	db ((Untitled_Subsong0_Track15 - ($ + 1)) & 255)
	db 134	; New track (14) for channel 3, as a reference (index 6).

; Pattern 5
	db 174	; State byte.
	db 31	; New height.
	db 0	; New transposition on channel 1.
	db 128	; New track (0) for channel 1, as a reference (index 0).
	db ((Untitled_Subsong0_Track3 - ($ + 2)) & #ff00) / 256	; New track (3) for channel 2, as an offset. Offset MSB, then LSB.
	db ((Untitled_Subsong0_Track3 - ($ + 1)) & 255)
	db ((Untitled_Subsong0_Track4 - ($ + 2)) & #ff00) / 256	; New track (4) for channel 3, as an offset. Offset MSB, then LSB.
	db ((Untitled_Subsong0_Track4 - ($ + 1)) & 255)

; Pattern 6
	db 0	; State byte.

; Pattern 7
	db 168	; State byte.
	db ((Untitled_Subsong0_Track16 - ($ + 2)) & #ff00) / 256	; New track (16) for channel 1, as an offset. Offset MSB, then LSB.
	db ((Untitled_Subsong0_Track16 - ($ + 1)) & 255)
	db ((Untitled_Subsong0_Track5 - ($ + 2)) & #ff00) / 256	; New track (5) for channel 2, as an offset. Offset MSB, then LSB.
	db ((Untitled_Subsong0_Track5 - ($ + 1)) & 255)
	db 132	; New track (6) for channel 3, as a reference (index 4).

; Pattern 8
	db 0	; State byte.

; Pattern 9
	db 40	; State byte.
	db 137	; New track (7) for channel 1, as a reference (index 9).
	db 138	; New track (8) for channel 2, as a reference (index 10).

; Pattern 10
	db 0	; State byte.

; Pattern 11
	db 0	; State byte.

; Pattern 12
	db 174	; State byte.
	db 15	; New height.
	db -2	; New transposition on channel 1.
	db 134	; New track (14) for channel 1, as a reference (index 6).
	db ((Untitled_Subsong0_Track15 - ($ + 2)) & #ff00) / 256	; New track (15) for channel 2, as an offset. Offset MSB, then LSB.
	db ((Untitled_Subsong0_Track15 - ($ + 1)) & 255)
	db 134	; New track (14) for channel 3, as a reference (index 6).

; Pattern 13
	db 236	; State byte.
	db 0	; New transposition on channel 1.
	db ((Untitled_Subsong0_Track17 - ($ + 2)) & #ff00) / 256	; New track (17) for channel 1, as an offset. Offset MSB, then LSB.
	db ((Untitled_Subsong0_Track17 - ($ + 1)) & 255)
	db ((Untitled_Subsong0_Track18 - ($ + 2)) & #ff00) / 256	; New track (18) for channel 2, as an offset. Offset MSB, then LSB.
	db ((Untitled_Subsong0_Track18 - ($ + 1)) & 255)
	db 5	; New transposition on channel 3.
	db ((Untitled_Subsong0_Track17 - ($ + 2)) & #ff00) / 256	; New track (17) for channel 3, as an offset. Offset MSB, then LSB.
	db ((Untitled_Subsong0_Track17 - ($ + 1)) & 255)

; Pattern 14
	db 234	; State byte.
	db 31	; New height.
	db 129	; New track (9) for channel 1, as a reference (index 1).
	db 130	; New track (10) for channel 2, as a reference (index 2).
	db 0	; New transposition on channel 3.
	db 131	; New track (11) for channel 3, as a reference (index 3).

; Pattern 15
	db 0	; State byte.

; Pattern 16
	db 0	; State byte.

; Pattern 17
	db 0	; State byte.

; Pattern 18
	db 168	; State byte.
	db 135	; New track (13) for channel 1, as a reference (index 7).
	db 139	; New track (19) for channel 2, as a reference (index 11).
	db 136	; New track (20) for channel 3, as a reference (index 8).

; Pattern 19
	db 168	; State byte.
	db 129	; New track (9) for channel 1, as a reference (index 1).
	db 130	; New track (10) for channel 2, as a reference (index 2).
	db 131	; New track (11) for channel 3, as a reference (index 3).

; Pattern 20
	db 0	; State byte.

; Pattern 21
	db 170	; State byte.
	db 63	; New height.
	db 135	; New track (13) for channel 1, as a reference (index 7).
	db 139	; New track (19) for channel 2, as a reference (index 11).
	db 136	; New track (20) for channel 3, as a reference (index 8).

; Pattern 22
	db 0	; State byte.

; Pattern 23
	db 168	; State byte.
	db ((Untitled_Subsong0_Track23 - ($ + 2)) & #ff00) / 256	; New track (23) for channel 1, as an offset. Offset MSB, then LSB.
	db ((Untitled_Subsong0_Track23 - ($ + 1)) & 255)
	db ((Untitled_Subsong0_Track21 - ($ + 2)) & #ff00) / 256	; New track (21) for channel 2, as an offset. Offset MSB, then LSB.
	db ((Untitled_Subsong0_Track21 - ($ + 1)) & 255)
	db ((Untitled_Subsong0_Track22 - ($ + 2)) & #ff00) / 256	; New track (22) for channel 3, as an offset. Offset MSB, then LSB.
	db ((Untitled_Subsong0_Track22 - ($ + 1)) & 255)

; Pattern 24
	db 138	; State byte.
	db 31	; New height.
	db 135	; New track (13) for channel 1, as a reference (index 7).
	db 136	; New track (20) for channel 3, as a reference (index 8).

; Pattern 25
	db 248	; State byte.
	db 140	; New track (24) for channel 1, as a reference (index 12).
	db -4	; New transposition on channel 2.
	db 140	; New track (24) for channel 2, as a reference (index 12).
	db 4	; New transposition on channel 3.
	db 140	; New track (24) for channel 3, as a reference (index 12).

	db 1	; End of the Song.
	db 0	; Speed to 0, meaning "end of song".
	dw Untitled_Subsong0_Loop

; The indexes of the tracks.
Untitled_Subsong0_TrackIndexes
	dw Untitled_Subsong0_Track0	; Track 0, index 0.
	dw Untitled_Subsong0_Track9	; Track 9, index 1.
	dw Untitled_Subsong0_Track10	; Track 10, index 2.
	dw Untitled_Subsong0_Track11	; Track 11, index 3.
	dw Untitled_Subsong0_Track6	; Track 6, index 4.
	dw Untitled_Subsong0_Track2	; Track 2, index 5.
	dw Untitled_Subsong0_Track14	; Track 14, index 6.
	dw Untitled_Subsong0_Track13	; Track 13, index 7.
	dw Untitled_Subsong0_Track20	; Track 20, index 8.
	dw Untitled_Subsong0_Track7	; Track 7, index 9.
	dw Untitled_Subsong0_Track8	; Track 8, index 10.
	dw Untitled_Subsong0_Track19	; Track 19, index 11.
	dw Untitled_Subsong0_Track24	; Track 24, index 12.

Untitled_Subsong0_Track0
	db 128	; Note reference (0). Secondary wait (1).
	db 128	; Note reference (0). Secondary wait (1).
	db 192	; Note reference (0). New wait (9).
	db 9	;   Escape wait value.
	db 206	; New escaped note: 50. New wait (5).
	db 50	;   Escape note value.
	db 5	;   Escape wait value.
	db 0	; Note reference (0). 
	db 207	; Same escaped note: 50. New wait (127).
	db 127	;   Escape wait value.

Untitled_Subsong0_Track1
	db 221	; Effect only. New wait (5).
	db 5	;   Escape wait value.
	db 242	;    Volume effect, with inverted volume: 15.
	db 12	; Note with effects flag
	db 190	; New instrument (3). New escaped note: 4. Secondary wait (1).
	db 4	;   Escape note value.
	db 3	;   Escape instrument value.
	db 82	;    Volume effect, with inverted volume: 5.
	db 12	; Note with effects flag
	db 143	; Same escaped note: 4. Secondary wait (1).
	db 82	;    Volume effect, with inverted volume: 5.
	db 12	; Note with effects flag
	db 143	; Same escaped note: 4. Secondary wait (1).
	db 82	;    Volume effect, with inverted volume: 5.
	db 12	; Note with effects flag
	db 207	; Same escaped note: 4. New wait (3).
	db 3	;   Escape wait value.
	db 82	;    Volume effect, with inverted volume: 5.
	db 143	; Same escaped note: 4. Secondary wait (1).
	db 15	; Same escaped note: 4. 
	db 143	; Same escaped note: 4. Secondary wait (1).
	db 15	; Same escaped note: 4. 
	db 143	; Same escaped note: 4. Secondary wait (1).
	db 207	; Same escaped note: 4. New wait (127).
	db 127	;   Escape wait value.

Untitled_Subsong0_Track2
	db 160	; Secondary instrument (2). Note reference (0). Secondary wait (1).
	db 160	; Secondary instrument (2). Note reference (0). Secondary wait (1).
	db 224	; Secondary instrument (2). Note reference (0). New wait (9).
	db 9	;   Escape wait value.
	db 238	; Secondary instrument (2). New escaped note: 50. New wait (5).
	db 50	;   Escape note value.
	db 5	;   Escape wait value.
	db 32	; Secondary instrument (2). Note reference (0). 
	db 239	; Secondary instrument (2). Same escaped note: 50. New wait (127).
	db 127	;   Escape wait value.

Untitled_Subsong0_Track3
	db 12	; Note with effects flag
	db 180	; New instrument (4). Note reference (4). Secondary wait (1).
	db 4	;   Escape instrument value.
	db 2	;    Volume effect, with inverted volume: 0.
	db 130	; Note reference (2). Secondary wait (1).
	db 132	; Note reference (4). Secondary wait (1).
	db 177	; New instrument (5). Note reference (1). Secondary wait (1).
	db 5	;   Escape instrument value.
	db 133	; Note reference (5). Secondary wait (1).
	db 129	; Note reference (1). Secondary wait (1).
	db 129	; Note reference (1). Secondary wait (1).
	db 183	; New instrument (4). Note reference (7). Secondary wait (1).
	db 4	;   Escape instrument value.
	db 177	; New instrument (5). Note reference (1). Secondary wait (1).
	db 5	;   Escape instrument value.
	db 133	; Note reference (5). Secondary wait (1).
	db 178	; New instrument (4). Note reference (2). Secondary wait (1).
	db 4	;   Escape instrument value.
	db 177	; New instrument (5). Note reference (1). Secondary wait (1).
	db 5	;   Escape instrument value.
	db 129	; Note reference (1). Secondary wait (1).
	db 183	; New instrument (4). Note reference (7). Secondary wait (1).
	db 4	;   Escape instrument value.
	db 177	; New instrument (5). Note reference (1). Secondary wait (1).
	db 5	;   Escape instrument value.
	db 197	; Note reference (5). New wait (127).
	db 127	;   Escape wait value.

Untitled_Subsong0_Track4
	db 161	; Secondary instrument (2). Note reference (1). Secondary wait (1).
	db 161	; Secondary instrument (2). Note reference (1). Secondary wait (1).
	db 225	; Secondary instrument (2). Note reference (1). New wait (9).
	db 9	;   Escape wait value.
	db 234	; Secondary instrument (2). Note reference (10). New wait (5).
	db 5	;   Escape wait value.
	db 33	; Secondary instrument (2). Note reference (1). 
	db 234	; Secondary instrument (2). Note reference (10). New wait (127).
	db 127	;   Escape wait value.

Untitled_Subsong0_Track5
	db 12	; Note with effects flag
	db 177	; New instrument (7). Note reference (1). Secondary wait (1).
	db 7	;   Escape instrument value.
	db 2	;    Volume effect, with inverted volume: 0.
	db 129	; Note reference (1). Secondary wait (1).
	db 181	; New instrument (6). Note reference (5). Secondary wait (1).
	db 6	;   Escape instrument value.
	db 177	; New instrument (5). Note reference (1). Secondary wait (1).
	db 5	;   Escape instrument value.
	db 133	; Note reference (5). Secondary wait (1).
	db 129	; Note reference (1). Secondary wait (1).
	db 181	; New instrument (6). Note reference (5). Secondary wait (1).
	db 6	;   Escape instrument value.
	db 186	; New instrument (7). Note reference (10). Secondary wait (1).
	db 7	;   Escape instrument value.
	db 177	; New instrument (5). Note reference (1). Secondary wait (1).
	db 5	;   Escape instrument value.
	db 133	; Note reference (5). Secondary wait (1).
	db 117	; New instrument (6). Note reference (5). Primary wait (0).
	db 6	;   Escape instrument value.
	db 12	; Note with effects flag
	db 97	; Secondary instrument (2). Note reference (1). Primary wait (0).
	db 34	;    Volume effect, with inverted volume: 2.
	db 12	; Note with effects flag
	db 181	; New instrument (5). Note reference (5). Secondary wait (1).
	db 5	;   Escape instrument value.
	db 2	;    Volume effect, with inverted volume: 0.
	db 129	; Note reference (1). Secondary wait (1).
	db 186	; New instrument (7). Note reference (10). Secondary wait (1).
	db 7	;   Escape instrument value.
	db 181	; New instrument (6). Note reference (5). Secondary wait (1).
	db 6	;   Escape instrument value.
	db 245	; New instrument (5). Note reference (5). New wait (127).
	db 5	;   Escape instrument value.
	db 127	;   Escape wait value.

Untitled_Subsong0_Track6
	db 174	; Secondary instrument (2). New escaped note: 64. Secondary wait (1).
	db 64	;   Escape note value.
	db 175	; Secondary instrument (2). Same escaped note: 64. Secondary wait (1).
	db 175	; Secondary instrument (2). Same escaped note: 64. Secondary wait (1).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 84	; Primary instrument (8). Note reference (4). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 84	; Primary instrument (8). Note reference (4). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 84	; Primary instrument (8). Note reference (4). Primary wait (0).
	db 84	; Primary instrument (8). Note reference (4). Primary wait (0).
	db 12	; Note with effects flag
	db 174	; Secondary instrument (2). New escaped note: 62. Secondary wait (1).
	db 62	;   Escape note value.
	db 2	;    Volume effect, with inverted volume: 0.
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 84	; Primary instrument (8). Note reference (4). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 84	; Primary instrument (8). Note reference (4). Primary wait (0).
	db 174	; Secondary instrument (2). New escaped note: 64. Secondary wait (1).
	db 64	;   Escape note value.
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 84	; Primary instrument (8). Note reference (4). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 84	; Primary instrument (8). Note reference (4). Primary wait (0).
	db 174	; Secondary instrument (2). New escaped note: 62. Secondary wait (1).
	db 62	;   Escape note value.
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 84	; Primary instrument (8). Note reference (4). Primary wait (0).
	db 84	; Primary instrument (8). Note reference (4). Primary wait (0).
	db 210	; Primary instrument (8). Note reference (2). New wait (127).
	db 127	;   Escape wait value.

Untitled_Subsong0_Track7
	db 128	; Note reference (0). Secondary wait (1).
	db 128	; Note reference (0). Secondary wait (1).
	db 128	; Note reference (0). Secondary wait (1).
	db 88	; Primary instrument (8). Note reference (8). Primary wait (0).
	db 94	; Primary instrument (8). New escaped note: 78. Primary wait (0).
	db 78	;   Escape note value.
	db 94	; Primary instrument (8). New escaped note: 79. Primary wait (0).
	db 79	;   Escape note value.
	db 94	; Primary instrument (8). New escaped note: 90. Primary wait (0).
	db 90	;   Escape note value.
	db 94	; Primary instrument (8). New escaped note: 78. Primary wait (0).
	db 78	;   Escape note value.
	db 88	; Primary instrument (8). Note reference (8). Primary wait (0).
	db 95	; Primary instrument (8). Same escaped note: 78. Primary wait (0).
	db 88	; Primary instrument (8). Note reference (8). Primary wait (0).
	db 142	; New escaped note: 50. Secondary wait (1).
	db 50	;   Escape note value.
	db 88	; Primary instrument (8). Note reference (8). Primary wait (0).
	db 94	; Primary instrument (8). New escaped note: 78. Primary wait (0).
	db 78	;   Escape note value.
	db 88	; Primary instrument (8). Note reference (8). Primary wait (0).
	db 94	; Primary instrument (8). New escaped note: 90. Primary wait (0).
	db 90	;   Escape note value.
	db 128	; Note reference (0). Secondary wait (1).
	db 95	; Primary instrument (8). Same escaped note: 90. Primary wait (0).
	db 94	; Primary instrument (8). New escaped note: 79. Primary wait (0).
	db 79	;   Escape note value.
	db 94	; Primary instrument (8). New escaped note: 90. Primary wait (0).
	db 90	;   Escape note value.
	db 88	; Primary instrument (8). Note reference (8). Primary wait (0).
	db 142	; New escaped note: 50. Secondary wait (1).
	db 50	;   Escape note value.
	db 88	; Primary instrument (8). Note reference (8). Primary wait (0).
	db 94	; Primary instrument (8). New escaped note: 78. Primary wait (0).
	db 78	;   Escape note value.
	db 94	; Primary instrument (8). New escaped note: 79. Primary wait (0).
	db 79	;   Escape note value.
	db 216	; Primary instrument (8). Note reference (8). New wait (127).
	db 127	;   Escape wait value.

Untitled_Subsong0_Track8
	db 177	; New instrument (9). Note reference (1). Secondary wait (1).
	db 9	;   Escape instrument value.
	db 129	; Note reference (1). Secondary wait (1).
	db 177	; New instrument (6). Note reference (1). Secondary wait (1).
	db 6	;   Escape instrument value.
	db 177	; New instrument (9). Note reference (1). Secondary wait (1).
	db 9	;   Escape instrument value.
	db 129	; Note reference (1). Secondary wait (1).
	db 139	; Note reference (11). Secondary wait (1).
	db 177	; New instrument (6). Note reference (1). Secondary wait (1).
	db 6	;   Escape instrument value.
	db 177	; New instrument (9). Note reference (1). Secondary wait (1).
	db 9	;   Escape instrument value.
	db 133	; Note reference (5). Secondary wait (1).
	db 129	; Note reference (1). Secondary wait (1).
	db 177	; New instrument (6). Note reference (1). Secondary wait (1).
	db 6	;   Escape instrument value.
	db 190	; New instrument (9). New escaped note: 33. Secondary wait (1).
	db 33	;   Escape note value.
	db 9	;   Escape instrument value.
	db 142	; New escaped note: 35. Secondary wait (1).
	db 35	;   Escape note value.
	db 139	; Note reference (11). Secondary wait (1).
	db 177	; New instrument (6). Note reference (1). Secondary wait (1).
	db 6	;   Escape instrument value.
	db 251	; New instrument (9). Note reference (11). New wait (127).
	db 9	;   Escape instrument value.
	db 127	;   Escape wait value.

Untitled_Subsong0_Track9
	db 12	; Note with effects flag
	db 160	; Secondary instrument (2). Note reference (0). Secondary wait (1).
	db 2	;    Volume effect, with inverted volume: 0.
	db 160	; Secondary instrument (2). Note reference (0). Secondary wait (1).
	db 160	; Secondary instrument (2). Note reference (0). Secondary wait (1).
	db 88	; Primary instrument (8). Note reference (8). Primary wait (0).
	db 94	; Primary instrument (8). New escaped note: 78. Primary wait (0).
	db 78	;   Escape note value.
	db 94	; Primary instrument (8). New escaped note: 79. Primary wait (0).
	db 79	;   Escape note value.
	db 94	; Primary instrument (8). New escaped note: 90. Primary wait (0).
	db 90	;   Escape note value.
	db 94	; Primary instrument (8). New escaped note: 78. Primary wait (0).
	db 78	;   Escape note value.
	db 88	; Primary instrument (8). Note reference (8). Primary wait (0).
	db 95	; Primary instrument (8). Same escaped note: 78. Primary wait (0).
	db 88	; Primary instrument (8). Note reference (8). Primary wait (0).
	db 174	; Secondary instrument (2). New escaped note: 50. Secondary wait (1).
	db 50	;   Escape note value.
	db 88	; Primary instrument (8). Note reference (8). Primary wait (0).
	db 94	; Primary instrument (8). New escaped note: 78. Primary wait (0).
	db 78	;   Escape note value.
	db 88	; Primary instrument (8). Note reference (8). Primary wait (0).
	db 94	; Primary instrument (8). New escaped note: 90. Primary wait (0).
	db 90	;   Escape note value.
	db 160	; Secondary instrument (2). Note reference (0). Secondary wait (1).
	db 95	; Primary instrument (8). Same escaped note: 90. Primary wait (0).
	db 94	; Primary instrument (8). New escaped note: 79. Primary wait (0).
	db 79	;   Escape note value.
	db 94	; Primary instrument (8). New escaped note: 90. Primary wait (0).
	db 90	;   Escape note value.
	db 88	; Primary instrument (8). Note reference (8). Primary wait (0).
	db 174	; Secondary instrument (2). New escaped note: 50. Secondary wait (1).
	db 50	;   Escape note value.
	db 88	; Primary instrument (8). Note reference (8). Primary wait (0).
	db 94	; Primary instrument (8). New escaped note: 78. Primary wait (0).
	db 78	;   Escape note value.
	db 94	; Primary instrument (8). New escaped note: 79. Primary wait (0).
	db 79	;   Escape note value.
	db 216	; Primary instrument (8). Note reference (8). New wait (127).
	db 127	;   Escape wait value.

Untitled_Subsong0_Track10
	db 12	; Note with effects flag
	db 177	; New instrument (9). Note reference (1). Secondary wait (1).
	db 9	;   Escape instrument value.
	db 2	;    Volume effect, with inverted volume: 0.
	db 129	; Note reference (1). Secondary wait (1).
	db 177	; New instrument (6). Note reference (1). Secondary wait (1).
	db 6	;   Escape instrument value.
	db 177	; New instrument (9). Note reference (1). Secondary wait (1).
	db 9	;   Escape instrument value.
	db 129	; Note reference (1). Secondary wait (1).
	db 139	; Note reference (11). Secondary wait (1).
	db 177	; New instrument (6). Note reference (1). Secondary wait (1).
	db 6	;   Escape instrument value.
	db 177	; New instrument (9). Note reference (1). Secondary wait (1).
	db 9	;   Escape instrument value.
	db 133	; Note reference (5). Secondary wait (1).
	db 129	; Note reference (1). Secondary wait (1).
	db 177	; New instrument (6). Note reference (1). Secondary wait (1).
	db 6	;   Escape instrument value.
	db 190	; New instrument (9). New escaped note: 33. Secondary wait (1).
	db 33	;   Escape note value.
	db 9	;   Escape instrument value.
	db 142	; New escaped note: 35. Secondary wait (1).
	db 35	;   Escape note value.
	db 139	; Note reference (11). Secondary wait (1).
	db 177	; New instrument (6). Note reference (1). Secondary wait (1).
	db 6	;   Escape instrument value.
	db 251	; New instrument (9). Note reference (11). New wait (127).
	db 9	;   Escape instrument value.
	db 127	;   Escape wait value.

Untitled_Subsong0_Track11
	db 12	; Note with effects flag
	db 190	; New instrument (10). New escaped note: 62. Secondary wait (1).
	db 62	;   Escape note value.
	db 10	;   Escape instrument value.
	db 2	;    Volume effect, with inverted volume: 0.
	db 142	; New escaped note: 64. Secondary wait (1).
	db 64	;   Escape note value.
	db 142	; New escaped note: 71. Secondary wait (1).
	db 71	;   Escape note value.
	db 142	; New escaped note: 62. Secondary wait (1).
	db 62	;   Escape note value.
	db 142	; New escaped note: 64. Secondary wait (1).
	db 64	;   Escape note value.
	db 142	; New escaped note: 69. Secondary wait (1).
	db 69	;   Escape note value.
	db 142	; New escaped note: 62. Secondary wait (1).
	db 62	;   Escape note value.
	db 142	; New escaped note: 64. Secondary wait (1).
	db 64	;   Escape note value.
	db 142	; New escaped note: 71. Secondary wait (1).
	db 71	;   Escape note value.
	db 142	; New escaped note: 62. Secondary wait (1).
	db 62	;   Escape note value.
	db 142	; New escaped note: 64. Secondary wait (1).
	db 64	;   Escape note value.
	db 142	; New escaped note: 74. Secondary wait (1).
	db 74	;   Escape note value.
	db 142	; New escaped note: 73. Secondary wait (1).
	db 73	;   Escape note value.
	db 142	; New escaped note: 69. Secondary wait (1).
	db 69	;   Escape note value.
	db 134	; Note reference (6). Secondary wait (1).
	db 207	; Same escaped note: 69. New wait (127).
	db 127	;   Escape wait value.

Untitled_Subsong0_Track12
	db 12	; Note with effects flag
	db 180	; New instrument (4). Note reference (4). Secondary wait (1).
	db 4	;   Escape instrument value.
	db 2	;    Volume effect, with inverted volume: 0.
	db 132	; Note reference (4). Secondary wait (1).
	db 132	; Note reference (4). Secondary wait (1).
	db 12	; Note with effects flag
	db 177	; New instrument (5). Note reference (1). Secondary wait (1).
	db 5	;   Escape instrument value.
	db 82	;    Volume effect, with inverted volume: 5.
	db 129	; Note reference (1). Secondary wait (1).
	db 133	; Note reference (5). Secondary wait (1).
	db 129	; Note reference (1). Secondary wait (1).
	db 12	; Note with effects flag
	db 190	; New instrument (4). New escaped note: 74. Secondary wait (1).
	db 74	;   Escape note value.
	db 4	;   Escape instrument value.
	db 2	;    Volume effect, with inverted volume: 0.
	db 12	; Note with effects flag
	db 177	; New instrument (5). Note reference (1). Secondary wait (1).
	db 5	;   Escape instrument value.
	db 82	;    Volume effect, with inverted volume: 5.
	db 129	; Note reference (1). Secondary wait (1).
	db 12	; Note with effects flag
	db 180	; New instrument (4). Note reference (4). Secondary wait (1).
	db 4	;   Escape instrument value.
	db 2	;    Volume effect, with inverted volume: 0.
	db 12	; Note with effects flag
	db 177	; New instrument (5). Note reference (1). Secondary wait (1).
	db 5	;   Escape instrument value.
	db 82	;    Volume effect, with inverted volume: 5.
	db 133	; Note reference (5). Secondary wait (1).
	db 12	; Note with effects flag
	db 191	; New instrument (4). Same escaped note: 74. Secondary wait (1).
	db 4	;   Escape instrument value.
	db 2	;    Volume effect, with inverted volume: 0.
	db 12	; Note with effects flag
	db 181	; New instrument (5). Note reference (5). Secondary wait (1).
	db 5	;   Escape instrument value.
	db 82	;    Volume effect, with inverted volume: 5.
	db 193	; Note reference (1). New wait (127).
	db 127	;   Escape wait value.

Untitled_Subsong0_Track13
	db 12	; Note with effects flag
	db 160	; Secondary instrument (2). Note reference (0). Secondary wait (1).
	db 18	;    Volume effect, with inverted volume: 1.
	db 160	; Secondary instrument (2). Note reference (0). Secondary wait (1).
	db 174	; Secondary instrument (2). New escaped note: 55. Secondary wait (1).
	db 55	;   Escape note value.
	db 160	; Secondary instrument (2). Note reference (0). Secondary wait (1).
	db 166	; Secondary instrument (2). Note reference (6). Secondary wait (1).
	db 160	; Secondary instrument (2). Note reference (0). Secondary wait (1).
	db 163	; Secondary instrument (2). Note reference (3). Secondary wait (1).
	db 160	; Secondary instrument (2). Note reference (0). Secondary wait (1).
	db 160	; Secondary instrument (2). Note reference (0). Secondary wait (1).
	db 160	; Secondary instrument (2). Note reference (0). Secondary wait (1).
	db 175	; Secondary instrument (2). Same escaped note: 55. Secondary wait (1).
	db 160	; Secondary instrument (2). Note reference (0). Secondary wait (1).
	db 166	; Secondary instrument (2). Note reference (6). Secondary wait (1).
	db 160	; Secondary instrument (2). Note reference (0). Secondary wait (1).
	db 163	; Secondary instrument (2). Note reference (3). Secondary wait (1).
	db 160	; Secondary instrument (2). Note reference (0). Secondary wait (1).
	db 160	; Secondary instrument (2). Note reference (0). Secondary wait (1).
	db 160	; Secondary instrument (2). Note reference (0). Secondary wait (1).
	db 174	; Secondary instrument (2). New escaped note: 50. Secondary wait (1).
	db 50	;   Escape note value.
	db 160	; Secondary instrument (2). Note reference (0). Secondary wait (1).
	db 166	; Secondary instrument (2). Note reference (6). Secondary wait (1).
	db 160	; Secondary instrument (2). Note reference (0). Secondary wait (1).
	db 163	; Secondary instrument (2). Note reference (3). Secondary wait (1).
	db 160	; Secondary instrument (2). Note reference (0). Secondary wait (1).
	db 160	; Secondary instrument (2). Note reference (0). Secondary wait (1).
	db 160	; Secondary instrument (2). Note reference (0). Secondary wait (1).
	db 174	; Secondary instrument (2). New escaped note: 56. Secondary wait (1).
	db 56	;   Escape note value.
	db 160	; Secondary instrument (2). Note reference (0). Secondary wait (1).
	db 166	; Secondary instrument (2). Note reference (6). Secondary wait (1).
	db 160	; Secondary instrument (2). Note reference (0). Secondary wait (1).
	db 163	; Secondary instrument (2). Note reference (3). Secondary wait (1).
	db 224	; Secondary instrument (2). Note reference (0). New wait (127).
	db 127	;   Escape wait value.

Untitled_Subsong0_Track14
	db 110	; Secondary instrument (2). New escaped note: 29. Primary wait (0).
	db 29	;   Escape note value.
	db 110	; Secondary instrument (2). New escaped note: 30. Primary wait (0).
	db 30	;   Escape note value.
	db 110	; Secondary instrument (2). New escaped note: 31. Primary wait (0).
	db 31	;   Escape note value.
	db 110	; Secondary instrument (2). New escaped note: 32. Primary wait (0).
	db 32	;   Escape note value.
	db 110	; Secondary instrument (2). New escaped note: 33. Primary wait (0).
	db 33	;   Escape note value.
	db 110	; Secondary instrument (2). New escaped note: 34. Primary wait (0).
	db 34	;   Escape note value.
	db 110	; Secondary instrument (2). New escaped note: 35. Primary wait (0).
	db 35	;   Escape note value.
	db 110	; Secondary instrument (2). New escaped note: 36. Primary wait (0).
	db 36	;   Escape note value.
	db 110	; Secondary instrument (2). New escaped note: 37. Primary wait (0).
	db 37	;   Escape note value.
	db 107	; Secondary instrument (2). Note reference (11). Primary wait (0).
	db 110	; Secondary instrument (2). New escaped note: 39. Primary wait (0).
	db 39	;   Escape note value.
	db 101	; Secondary instrument (2). Note reference (5). Primary wait (0).
	db 110	; Secondary instrument (2). New escaped note: 41. Primary wait (0).
	db 41	;   Escape note value.
	db 110	; Secondary instrument (2). New escaped note: 42. Primary wait (0).
	db 42	;   Escape note value.
	db 110	; Secondary instrument (2). New escaped note: 43. Primary wait (0).
	db 43	;   Escape note value.
	db 238	; Secondary instrument (2). New escaped note: 44. New wait (127).
	db 44	;   Escape note value.
	db 127	;   Escape wait value.

Untitled_Subsong0_Track15
	db 12	; Note with effects flag
	db 177	; New instrument (5). Note reference (1). Secondary wait (1).
	db 5	;   Escape instrument value.
	db 82	;    Volume effect, with inverted volume: 5.
	db 133	; Note reference (5). Secondary wait (1).
	db 133	; Note reference (5). Secondary wait (1).
	db 12	; Note with effects flag
	db 129	; Note reference (1). Secondary wait (1).
	db 50	;    Volume effect, with inverted volume: 3.
	db 129	; Note reference (1). Secondary wait (1).
	db 133	; Note reference (5). Secondary wait (1).
	db 129	; Note reference (1). Secondary wait (1).
	db 193	; Note reference (1). New wait (127).
	db 127	;   Escape wait value.

Untitled_Subsong0_Track16
	db 128	; Note reference (0). Secondary wait (1).
	db 128	; Note reference (0). Secondary wait (1).
	db 128	; Note reference (0). Secondary wait (1).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 87	; Primary instrument (8). Note reference (7). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 87	; Primary instrument (8). Note reference (7). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 87	; Primary instrument (8). Note reference (7). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 87	; Primary instrument (8). Note reference (7). Primary wait (0).
	db 142	; New escaped note: 50. Secondary wait (1).
	db 50	;   Escape note value.
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 87	; Primary instrument (8). Note reference (7). Primary wait (0).
	db 87	; Primary instrument (8). Note reference (7). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 128	; Note reference (0). Secondary wait (1).
	db 87	; Primary instrument (8). Note reference (7). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 87	; Primary instrument (8). Note reference (7). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 143	; Same escaped note: 50. Secondary wait (1).
	db 87	; Primary instrument (8). Note reference (7). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 87	; Primary instrument (8). Note reference (7). Primary wait (0).
	db 210	; Primary instrument (8). Note reference (2). New wait (127).
	db 127	;   Escape wait value.

Untitled_Subsong0_Track17
	db 12	; Note with effects flag
	db 190	; New instrument (11). New escaped note: 43. Secondary wait (1).
	db 43	;   Escape note value.
	db 11	;   Escape instrument value.
	db 98	;    Volume effect, with inverted volume: 6.
	db 93	; Effect only. Primary wait (0).
	db 244	;    Pitch up: 256.
	db 0	;    Pitch, LSB.
	db 129	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 244	;    Pitch up: 256.
	db 0	;    Pitch, LSB.
	db 129	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 244	;    Pitch up: 256.
	db 0	;    Pitch, LSB.
	db 129	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 244	;    Pitch up: 256.
	db 0	;    Pitch, LSB.
	db 129	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 244	;    Pitch up: 256.
	db 0	;    Pitch, LSB.
	db 129	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 244	;    Pitch up: 256.
	db 0	;    Pitch, LSB.
	db 129	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 244	;    Pitch up: 256.
	db 0	;    Pitch, LSB.
	db 129	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 244	;    Pitch up: 256.
	db 0	;    Pitch, LSB.
	db 129	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 244	;    Pitch up: 256.
	db 0	;    Pitch, LSB.
	db 129	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 244	;    Pitch up: 256.
	db 0	;    Pitch, LSB.
	db 129	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 244	;    Pitch up: 256.
	db 0	;    Pitch, LSB.
	db 129	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 244	;    Pitch up: 256.
	db 0	;    Pitch, LSB.
	db 129	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 244	;    Pitch up: 256.
	db 0	;    Pitch, LSB.
	db 129	;    Pitch, MSB.
	db 221	; Effect only. New wait (127).
	db 127	;   Escape wait value.
	db 244	;    Pitch up: 256.
	db 0	;    Pitch, LSB.
	db 129	;    Pitch, MSB.

Untitled_Subsong0_Track18
	db 12	; Note with effects flag
	db 254	; New instrument (12). New escaped note: 36. New wait (3).
	db 36	;   Escape note value.
	db 12	;   Escape instrument value.
	db 3	;   Escape wait value.
	db 82	;    Volume effect, with inverted volume: 5.
	db 12	; Note with effects flag
	db 15	; Same escaped note: 36. 
	db 66	;    Volume effect, with inverted volume: 4.
	db 12	; Note with effects flag
	db 15	; Same escaped note: 36. 
	db 50	;    Volume effect, with inverted volume: 3.
	db 12	; Note with effects flag
	db 191	; New instrument (6). Same escaped note: 36. Secondary wait (1).
	db 6	;   Escape instrument value.
	db 2	;    Volume effect, with inverted volume: 0.
	db 79	; Same escaped note: 36. Primary wait (0).
	db 207	; Same escaped note: 36. New wait (127).
	db 127	;   Escape wait value.

Untitled_Subsong0_Track19
	db 12	; Note with effects flag
	db 191	; New instrument (6). Same escaped note: 24. Secondary wait (1).
	db 6	;   Escape instrument value.
	db 2	;    Volume effect, with inverted volume: 0.
	db 191	; New instrument (9). Same escaped note: 24. Secondary wait (1).
	db 9	;   Escape instrument value.
	db 142	; New escaped note: 36. Secondary wait (1).
	db 36	;   Escape note value.
	db 190	; New instrument (6). New escaped note: 24. Secondary wait (1).
	db 24	;   Escape note value.
	db 6	;   Escape instrument value.
	db 190	; New instrument (9). New escaped note: 36. Secondary wait (1).
	db 36	;   Escape note value.
	db 9	;   Escape instrument value.
	db 142	; New escaped note: 24. Secondary wait (1).
	db 24	;   Escape note value.
	db 191	; New instrument (6). Same escaped note: 24. Secondary wait (1).
	db 6	;   Escape instrument value.
	db 190	; New instrument (9). New escaped note: 36. Secondary wait (1).
	db 36	;   Escape note value.
	db 9	;   Escape instrument value.
	db 186	; New instrument (6). Note reference (10). Secondary wait (1).
	db 6	;   Escape instrument value.
	db 186	; New instrument (9). Note reference (10). Secondary wait (1).
	db 9	;   Escape instrument value.
	db 139	; Note reference (11). Secondary wait (1).
	db 186	; New instrument (6). Note reference (10). Secondary wait (1).
	db 6	;   Escape instrument value.
	db 187	; New instrument (9). Note reference (11). Secondary wait (1).
	db 9	;   Escape instrument value.
	db 138	; Note reference (10). Secondary wait (1).
	db 187	; New instrument (6). Note reference (11). Secondary wait (1).
	db 6	;   Escape instrument value.
	db 186	; New instrument (9). Note reference (10). Secondary wait (1).
	db 9	;   Escape instrument value.
	db 177	; New instrument (6). Note reference (1). Secondary wait (1).
	db 6	;   Escape instrument value.
	db 181	; New instrument (9). Note reference (5). Secondary wait (1).
	db 9	;   Escape instrument value.
	db 133	; Note reference (5). Secondary wait (1).
	db 190	; New instrument (6). New escaped note: 45. Secondary wait (1).
	db 45	;   Escape note value.
	db 6	;   Escape instrument value.
	db 191	; New instrument (9). Same escaped note: 45. Secondary wait (1).
	db 9	;   Escape instrument value.
	db 142	; New escaped note: 47. Secondary wait (1).
	db 47	;   Escape note value.
	db 177	; New instrument (6). Note reference (1). Secondary wait (1).
	db 6	;   Escape instrument value.
	db 181	; New instrument (9). Note reference (5). Secondary wait (1).
	db 9	;   Escape instrument value.
	db 129	; Note reference (1). Secondary wait (1).
	db 181	; New instrument (6). Note reference (5). Secondary wait (1).
	db 6	;   Escape instrument value.
	db 177	; New instrument (9). Note reference (1). Secondary wait (1).
	db 9	;   Escape instrument value.
	db 142	; New escaped note: 45. Secondary wait (1).
	db 45	;   Escape note value.
	db 177	; New instrument (6). Note reference (1). Secondary wait (1).
	db 6	;   Escape instrument value.
	db 190	; New instrument (9). New escaped note: 47. Secondary wait (1).
	db 47	;   Escape note value.
	db 9	;   Escape instrument value.
	db 176	; New instrument (6). Note reference (0). Secondary wait (1).
	db 6	;   Escape instrument value.
	db 64	; Note reference (0). Primary wait (0).
	db 192	; Note reference (0). New wait (127).
	db 127	;   Escape wait value.

Untitled_Subsong0_Track20
	db 12	; Note with effects flag
	db 185	; New instrument (13). Note reference (9). Secondary wait (1).
	db 13	;   Escape instrument value.
	db 18	;    Volume effect, with inverted volume: 1.
	db 137	; Note reference (9). Secondary wait (1).
	db 137	; Note reference (9). Secondary wait (1).
	db 137	; Note reference (9). Secondary wait (1).
	db 137	; Note reference (9). Secondary wait (1).
	db 137	; Note reference (9). Secondary wait (1).
	db 137	; Note reference (9). Secondary wait (1).
	db 137	; Note reference (9). Secondary wait (1).
	db 182	; New instrument (15). Note reference (6). Secondary wait (1).
	db 15	;   Escape instrument value.
	db 134	; Note reference (6). Secondary wait (1).
	db 134	; Note reference (6). Secondary wait (1).
	db 134	; Note reference (6). Secondary wait (1).
	db 134	; Note reference (6). Secondary wait (1).
	db 134	; Note reference (6). Secondary wait (1).
	db 134	; Note reference (6). Secondary wait (1).
	db 134	; Note reference (6). Secondary wait (1).
	db 179	; New instrument (14). Note reference (3). Secondary wait (1).
	db 14	;   Escape instrument value.
	db 131	; Note reference (3). Secondary wait (1).
	db 131	; Note reference (3). Secondary wait (1).
	db 131	; Note reference (3). Secondary wait (1).
	db 131	; Note reference (3). Secondary wait (1).
	db 131	; Note reference (3). Secondary wait (1).
	db 131	; Note reference (3). Secondary wait (1).
	db 131	; Note reference (3). Secondary wait (1).
	db 179	; New instrument (15). Note reference (3). Secondary wait (1).
	db 15	;   Escape instrument value.
	db 131	; Note reference (3). Secondary wait (1).
	db 131	; Note reference (3). Secondary wait (1).
	db 131	; Note reference (3). Secondary wait (1).
	db 131	; Note reference (3). Secondary wait (1).
	db 131	; Note reference (3). Secondary wait (1).
	db 131	; Note reference (3). Secondary wait (1).
	db 195	; Note reference (3). New wait (127).
	db 127	;   Escape wait value.

Untitled_Subsong0_Track21
	db 12	; Note with effects flag
	db 191	; New instrument (6). Same escaped note: 24. Secondary wait (1).
	db 6	;   Escape instrument value.
	db 2	;    Volume effect, with inverted volume: 0.
	db 191	; New instrument (9). Same escaped note: 24. Secondary wait (1).
	db 9	;   Escape instrument value.
	db 190	; New instrument (6). New escaped note: 36. Secondary wait (1).
	db 36	;   Escape note value.
	db 6	;   Escape instrument value.
	db 190	; New instrument (9). New escaped note: 24. Secondary wait (1).
	db 24	;   Escape note value.
	db 9	;   Escape instrument value.
	db 190	; New instrument (6). New escaped note: 36. Secondary wait (1).
	db 36	;   Escape note value.
	db 6	;   Escape instrument value.
	db 190	; New instrument (9). New escaped note: 24. Secondary wait (1).
	db 24	;   Escape note value.
	db 9	;   Escape instrument value.
	db 191	; New instrument (6). Same escaped note: 24. Secondary wait (1).
	db 6	;   Escape instrument value.
	db 190	; New instrument (9). New escaped note: 36. Secondary wait (1).
	db 36	;   Escape note value.
	db 9	;   Escape instrument value.
	db 186	; New instrument (6). Note reference (10). Secondary wait (1).
	db 6	;   Escape instrument value.
	db 186	; New instrument (9). Note reference (10). Secondary wait (1).
	db 9	;   Escape instrument value.
	db 187	; New instrument (6). Note reference (11). Secondary wait (1).
	db 6	;   Escape instrument value.
	db 186	; New instrument (9). Note reference (10). Secondary wait (1).
	db 9	;   Escape instrument value.
	db 187	; New instrument (6). Note reference (11). Secondary wait (1).
	db 6	;   Escape instrument value.
	db 186	; New instrument (9). Note reference (10). Secondary wait (1).
	db 9	;   Escape instrument value.
	db 187	; New instrument (6). Note reference (11). Secondary wait (1).
	db 6	;   Escape instrument value.
	db 186	; New instrument (9). Note reference (10). Secondary wait (1).
	db 9	;   Escape instrument value.
	db 177	; New instrument (6). Note reference (1). Secondary wait (1).
	db 6	;   Escape instrument value.
	db 181	; New instrument (9). Note reference (5). Secondary wait (1).
	db 9	;   Escape instrument value.
	db 181	; New instrument (6). Note reference (5). Secondary wait (1).
	db 6	;   Escape instrument value.
	db 190	; New instrument (9). New escaped note: 45. Secondary wait (1).
	db 45	;   Escape note value.
	db 9	;   Escape instrument value.
	db 191	; New instrument (6). Same escaped note: 45. Secondary wait (1).
	db 6	;   Escape instrument value.
	db 190	; New instrument (9). New escaped note: 47. Secondary wait (1).
	db 47	;   Escape note value.
	db 9	;   Escape instrument value.
	db 177	; New instrument (6). Note reference (1). Secondary wait (1).
	db 6	;   Escape instrument value.
	db 181	; New instrument (9). Note reference (5). Secondary wait (1).
	db 9	;   Escape instrument value.
	db 177	; New instrument (6). Note reference (1). Secondary wait (1).
	db 6	;   Escape instrument value.
	db 181	; New instrument (9). Note reference (5). Secondary wait (1).
	db 9	;   Escape instrument value.
	db 177	; New instrument (6). Note reference (1). Secondary wait (1).
	db 6	;   Escape instrument value.
	db 190	; New instrument (9). New escaped note: 45. Secondary wait (1).
	db 45	;   Escape note value.
	db 9	;   Escape instrument value.
	db 177	; New instrument (6). Note reference (1). Secondary wait (1).
	db 6	;   Escape instrument value.
	db 190	; New instrument (9). New escaped note: 47. Secondary wait (1).
	db 47	;   Escape note value.
	db 9	;   Escape instrument value.
	db 176	; New instrument (6). Note reference (0). Secondary wait (1).
	db 6	;   Escape instrument value.
	db 64	; Note reference (0). Primary wait (0).
	db 192	; Note reference (0). New wait (127).
	db 127	;   Escape wait value.

Untitled_Subsong0_Track22
	db 12	; Note with effects flag
	db 121	; New instrument (13). Note reference (9). Primary wait (0).
	db 13	;   Escape instrument value.
	db 18	;    Volume effect, with inverted volume: 1.
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 73	; Note reference (9). Primary wait (0).
	db 87	; Primary instrument (8). Note reference (7). Primary wait (0).
	db 73	; Note reference (9). Primary wait (0).
	db 94	; Primary instrument (8). New escaped note: 83. Primary wait (0).
	db 83	;   Escape note value.
	db 73	; Note reference (9). Primary wait (0).
	db 87	; Primary instrument (8). Note reference (7). Primary wait (0).
	db 73	; Note reference (9). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 73	; Note reference (9). Primary wait (0).
	db 87	; Primary instrument (8). Note reference (7). Primary wait (0).
	db 73	; Note reference (9). Primary wait (0).
	db 95	; Primary instrument (8). Same escaped note: 83. Primary wait (0).
	db 73	; Note reference (9). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 118	; New instrument (15). Note reference (6). Primary wait (0).
	db 15	;   Escape instrument value.
	db 95	; Primary instrument (8). Same escaped note: 83. Primary wait (0).
	db 70	; Note reference (6). Primary wait (0).
	db 87	; Primary instrument (8). Note reference (7). Primary wait (0).
	db 70	; Note reference (6). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 70	; Note reference (6). Primary wait (0).
	db 95	; Primary instrument (8). Same escaped note: 83. Primary wait (0).
	db 70	; Note reference (6). Primary wait (0).
	db 87	; Primary instrument (8). Note reference (7). Primary wait (0).
	db 70	; Note reference (6). Primary wait (0).
	db 95	; Primary instrument (8). Same escaped note: 83. Primary wait (0).
	db 70	; Note reference (6). Primary wait (0).
	db 95	; Primary instrument (8). Same escaped note: 83. Primary wait (0).
	db 70	; Note reference (6). Primary wait (0).
	db 95	; Primary instrument (8). Same escaped note: 83. Primary wait (0).
	db 115	; New instrument (14). Note reference (3). Primary wait (0).
	db 14	;   Escape instrument value.
	db 87	; Primary instrument (8). Note reference (7). Primary wait (0).
	db 67	; Note reference (3). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 67	; Note reference (3). Primary wait (0).
	db 87	; Primary instrument (8). Note reference (7). Primary wait (0).
	db 67	; Note reference (3). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 67	; Note reference (3). Primary wait (0).
	db 87	; Primary instrument (8). Note reference (7). Primary wait (0).
	db 67	; Note reference (3). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 67	; Note reference (3). Primary wait (0).
	db 95	; Primary instrument (8). Same escaped note: 83. Primary wait (0).
	db 67	; Note reference (3). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 115	; New instrument (15). Note reference (3). Primary wait (0).
	db 15	;   Escape instrument value.
	db 87	; Primary instrument (8). Note reference (7). Primary wait (0).
	db 67	; Note reference (3). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 67	; Note reference (3). Primary wait (0).
	db 87	; Primary instrument (8). Note reference (7). Primary wait (0).
	db 67	; Note reference (3). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 67	; Note reference (3). Primary wait (0).
	db 87	; Primary instrument (8). Note reference (7). Primary wait (0).
	db 67	; Note reference (3). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 67	; Note reference (3). Primary wait (0).
	db 87	; Primary instrument (8). Note reference (7). Primary wait (0).
	db 67	; Note reference (3). Primary wait (0).
	db 223	; Primary instrument (8). Same escaped note: 83. New wait (127).
	db 127	;   Escape wait value.

Untitled_Subsong0_Track23
	db 12	; Note with effects flag
	db 96	; Secondary instrument (2). Note reference (0). Primary wait (0).
	db 18	;    Volume effect, with inverted volume: 1.
	db 84	; Primary instrument (8). Note reference (4). Primary wait (0).
	db 96	; Secondary instrument (2). Note reference (0). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 110	; Secondary instrument (2). New escaped note: 55. Primary wait (0).
	db 55	;   Escape note value.
	db 84	; Primary instrument (8). Note reference (4). Primary wait (0).
	db 96	; Secondary instrument (2). Note reference (0). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 102	; Secondary instrument (2). Note reference (6). Primary wait (0).
	db 84	; Primary instrument (8). Note reference (4). Primary wait (0).
	db 96	; Secondary instrument (2). Note reference (0). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 99	; Secondary instrument (2). Note reference (3). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 96	; Secondary instrument (2). Note reference (0). Primary wait (0).
	db 84	; Primary instrument (8). Note reference (4). Primary wait (0).
	db 96	; Secondary instrument (2). Note reference (0). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 96	; Secondary instrument (2). Note reference (0). Primary wait (0).
	db 84	; Primary instrument (8). Note reference (4). Primary wait (0).
	db 111	; Secondary instrument (2). Same escaped note: 55. Primary wait (0).
	db 84	; Primary instrument (8). Note reference (4). Primary wait (0).
	db 96	; Secondary instrument (2). Note reference (0). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 102	; Secondary instrument (2). Note reference (6). Primary wait (0).
	db 84	; Primary instrument (8). Note reference (4). Primary wait (0).
	db 96	; Secondary instrument (2). Note reference (0). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 99	; Secondary instrument (2). Note reference (3). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 96	; Secondary instrument (2). Note reference (0). Primary wait (0).
	db 84	; Primary instrument (8). Note reference (4). Primary wait (0).
	db 96	; Secondary instrument (2). Note reference (0). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 96	; Secondary instrument (2). Note reference (0). Primary wait (0).
	db 84	; Primary instrument (8). Note reference (4). Primary wait (0).
	db 110	; Secondary instrument (2). New escaped note: 50. Primary wait (0).
	db 50	;   Escape note value.
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 96	; Secondary instrument (2). Note reference (0). Primary wait (0).
	db 84	; Primary instrument (8). Note reference (4). Primary wait (0).
	db 102	; Secondary instrument (2). Note reference (6). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 96	; Secondary instrument (2). Note reference (0). Primary wait (0).
	db 84	; Primary instrument (8). Note reference (4). Primary wait (0).
	db 99	; Secondary instrument (2). Note reference (3). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 96	; Secondary instrument (2). Note reference (0). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 96	; Secondary instrument (2). Note reference (0). Primary wait (0).
	db 84	; Primary instrument (8). Note reference (4). Primary wait (0).
	db 96	; Secondary instrument (2). Note reference (0). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 110	; Secondary instrument (2). New escaped note: 56. Primary wait (0).
	db 56	;   Escape note value.
	db 84	; Primary instrument (8). Note reference (4). Primary wait (0).
	db 96	; Secondary instrument (2). Note reference (0). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 102	; Secondary instrument (2). Note reference (6). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 96	; Secondary instrument (2). Note reference (0). Primary wait (0).
	db 84	; Primary instrument (8). Note reference (4). Primary wait (0).
	db 99	; Secondary instrument (2). Note reference (3). Primary wait (0).
	db 82	; Primary instrument (8). Note reference (2). Primary wait (0).
	db 96	; Secondary instrument (2). Note reference (0). Primary wait (0).
	db 212	; Primary instrument (8). Note reference (4). New wait (127).
	db 127	;   Escape wait value.

Untitled_Subsong0_Track24
	db 12	; Note with effects flag
	db 126	; New instrument (11). New escaped note: 53. Primary wait (0).
	db 53	;   Escape note value.
	db 11	;   Escape instrument value.
	db 19	;    Volume effect, with inverted volume: 1.
	db 244	;    Pitch down: 2048.
	db 0	;    Pitch, LSB.
	db 8	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 244	;    Pitch down: 2048.
	db 0	;    Pitch, LSB.
	db 8	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 244	;    Pitch down: 2048.
	db 0	;    Pitch, LSB.
	db 8	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 244	;    Pitch down: 2048.
	db 0	;    Pitch, LSB.
	db 8	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 244	;    Pitch down: 2048.
	db 0	;    Pitch, LSB.
	db 8	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 244	;    Pitch down: 2048.
	db 0	;    Pitch, LSB.
	db 8	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 244	;    Pitch down: 2048.
	db 0	;    Pitch, LSB.
	db 8	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 244	;    Pitch down: 2048.
	db 0	;    Pitch, LSB.
	db 8	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 244	;    Pitch down: 2048.
	db 0	;    Pitch, LSB.
	db 8	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 244	;    Pitch down: 2048.
	db 0	;    Pitch, LSB.
	db 8	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 244	;    Pitch down: 2048.
	db 0	;    Pitch, LSB.
	db 8	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 244	;    Pitch down: 2048.
	db 0	;    Pitch, LSB.
	db 8	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 244	;    Pitch down: 2048.
	db 0	;    Pitch, LSB.
	db 8	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 244	;    Pitch down: 2048.
	db 0	;    Pitch, LSB.
	db 8	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 244	;    Pitch down: 2048.
	db 0	;    Pitch, LSB.
	db 8	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 243	;    Volume effect, with inverted volume: 15.
	db 244	;    Pitch down: 2048.
	db 0	;    Pitch, LSB.
	db 8	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 3	;    Volume effect, with inverted volume: 0.
	db 244	;    Pitch down: 2048.
	db 0	;    Pitch, LSB.
	db 8	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 243	;    Volume effect, with inverted volume: 15.
	db 244	;    Pitch down: 2048.
	db 0	;    Pitch, LSB.
	db 8	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 3	;    Volume effect, with inverted volume: 0.
	db 244	;    Pitch down: 2048.
	db 0	;    Pitch, LSB.
	db 8	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 244	;    Pitch down: 2048.
	db 0	;    Pitch, LSB.
	db 8	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 244	;    Pitch down: 2048.
	db 0	;    Pitch, LSB.
	db 8	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 243	;    Volume effect, with inverted volume: 15.
	db 244	;    Pitch down: 2048.
	db 0	;    Pitch, LSB.
	db 8	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 3	;    Volume effect, with inverted volume: 0.
	db 244	;    Pitch down: 2048.
	db 0	;    Pitch, LSB.
	db 8	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 244	;    Pitch down: 2048.
	db 0	;    Pitch, LSB.
	db 8	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 244	;    Pitch down: 2048.
	db 0	;    Pitch, LSB.
	db 8	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 243	;    Volume effect, with inverted volume: 15.
	db 244	;    Pitch down: 2048.
	db 0	;    Pitch, LSB.
	db 8	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 3	;    Volume effect, with inverted volume: 0.
	db 244	;    Pitch down: 2048.
	db 0	;    Pitch, LSB.
	db 8	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 243	;    Volume effect, with inverted volume: 15.
	db 244	;    Pitch down: 2048.
	db 0	;    Pitch, LSB.
	db 8	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 3	;    Volume effect, with inverted volume: 0.
	db 244	;    Pitch down: 2048.
	db 0	;    Pitch, LSB.
	db 8	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 244	;    Pitch down: 2048.
	db 0	;    Pitch, LSB.
	db 8	;    Pitch, MSB.
	db 93	; Effect only. Primary wait (0).
	db 244	;    Pitch down: 2048.
	db 0	;    Pitch, LSB.
	db 8	;    Pitch, MSB.
	db 221	; Effect only. New wait (127).
	db 127	;   Escape wait value.
	db 244	;    Pitch down: 2048.
	db 0	;    Pitch, LSB.
	db 8	;    Pitch, MSB.

; The note indexes.
Untitled_Subsong0_NoteIndexes
	db 52	; Note for index 0.
	db 28	; Note for index 1.
	db 88	; Note for index 2.
	db 59	; Note for index 3.
	db 76	; Note for index 4.
	db 40	; Note for index 5.
	db 57	; Note for index 6.
	db 86	; Note for index 7.
	db 91	; Note for index 8.
	db 60	; Note for index 9.
	db 26	; Note for index 10.
	db 38	; Note for index 11.

