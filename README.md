# GameOfLife---Verilog

--------------
Descriere tema
--------------

Implementati in Verilog un circuit secvential sincron care simuleaza executia 
unui automat celular pentru o lume bidimensionala finita cu dimensiunea de 64×64
de celule. Fiecare celula se poate afla intr-una din doua stari notate cu 0 si,
respectiv, 1. Executia automatului consta in calcularea unei noi generatii a 
lumii pe baza unei reguli, pornind de la generatia curenta.

-------------------------------------
Prezentarea generala a solutiei alese 
-------------------------------------

Pentru rezolvarea problemei am folosit doua blocuri always: unul care se executa
la orice eveniment de modificare a semnalelor folosite in cadrul blocului si un
bloc always@edge-triggered care se executa pe frontul crescator al semnalului 
de ceas (clk). In cel de-al doilea bloc se executa atribuirile non-blocante, unde
la fiecare front crescator se seteaza noile valori ale starii (state), index-ului
de rand (index_row), index-ului de coloana (index_column) si a semnalului update_done
care trebuie sa isi mentina valoarea 'high' timp de un ciclu de ceas, iar in primul
bloc modelam starile automatului.

Diagrama de stari a automatului celular este urmatoarea:

                                +---------+
                                |  START  |
                                +----+----+
                                     |
                                     |
                                     v
                     +---------------+---------------+
                     |  setPreviousRowToCurrentRow   | <--------------+
                     +---------------+---------------+                |
                                     |                                |
                                     |                                |
                                     v                                |
                               +-----+-----+                          |
    +------------------------> |  readRow  |                          |
    |                          +-----+-----+                          |
    |                                |                                |
    | (index_column < 63)            |                                |
    |                                v                                |
    |               +----------------+-----------------+              |
    +---------------+  incrementColumnToReadEntireRow  |              |
                    +----------------+-----------------+              |
                                     |                                |
                                     | (index_column = 63)            |
                                     v                                |
                              +------+-----+                          |
    +-----------------------> |  readCell  |                          |
    |                         +------+-----+                          |
    |                                |                                |
    |                                |                                |
    |                                v                                |
    |                         +------+------+                         |
    |                         |  readNorth  |                         |
    |                         +------+------+                         |
    |                                |                                |
    |                                |                                |
    |                                v                                |
    |                         +------+------+                         |
    |                         |  readSouth  |                         |
    |                         +------+------+                         |
    |                                |                                |
    |                                |                                |
    |                                v                                |
    |                         +------+-----+                          |
    |                         |  readWest  |                          |
    |                         +------+-----+                          |
    |                                |                                |
    |                                |                                |
    |                                v                                |
    |                         +------+-----+                          |
    |                         |  readEast  |                          |
    |                         +------+-----+                          |
    |                                |                                |
    |                                |                                |
    |                                v                                |
    |                         +------+------+                         |
    |                         |  writeCell  |                         |
    |                         +------+------+                         |
    |                                |                                |
    |                                |                                |
    |    (index_column < 63)         v          (index_column = 63)   |
    |                         +------+------+                         |
    +-------------------------+  increment  +-------------------------+
                              +-------------+

---------------------------------------
Descrierea starilor automatului celular
---------------------------------------

La inceputul fisierului am definit starile automatului pentru a lucra direct cu 
numele acestora si a putea urmari mai usor evolutia lor.

* STAREA 0 - start: setam starea urmatoare a starii(next_state), a index-ului
            de rand si de coloana (next_index_row,  next_index_column) cu 0 si 
            trecem la urmatoarea stare din automat (setPreviousRowToCurrentRow)
* STAREA 1 - setPreviousRowToCurrentRow: in urmatoarele doua stari vom citi din 
            matrice tot randul curent (current_row) pentru a avea acces la veci-
            nii din est si vest. Atunci cand se trece la randul urmator trebuie 
            sa retinem randul precedent (previous_row) pentru a sti valorile ve-
            cinilor din sud inainte de a fi modificate/scrise. Definim doi vec-
            tori care initial au elementele egale cu 0: previous_row si current_
            row. In aceasta stare retinem in previous_row valorile din current_row, 
            atunci cand se trece la un rand urmator. 
            OBS: Pentru prima iteratie previous_row ramane 0.
* STAREA 2 -  readRow: vrem sa citim un rand intreg din matrice si vom seta row
            si col cu valorile index-ului de rand si de coloana (index_row, 
            index_column). Inainte de case am setat semnalul world_we cu 0 pentru
            a putea citi din matrice, iar acum retinem valoarea celulei (world_in)
            in vectorul current_row. La prima executie aceasta stare populeaza 
            vectorul cu valoarea de pe prima coloana. Pentru a citi si urmatoarele
            valori din rand ne folosim de starea incrementColumnToReadEntireRow.
* STAREA 3 - incrementColumnToReadEntireRow: aici vom incrementa index-ul de 
            coloana pentru a putea citi tot randul. Daca nu s-a ajuns la ultima
            coloana (index_column == 63), atunci ne ducem cu noua valoare a lui
            index_column in starea readRow pentru a putea retine valoarea urma-
            toarei celule de pe acelasi rand in vectorul current_row. Se repeta 
            acesta trece din starea readRow in incrementColumnToReadEntireRow 
            pana se ajunge la ultima coloana. Dupa citirea intregului rand, setam
            next_index_column cu 0 pentru a reveni la index-ul celulei la care ne
            aflam cu executia si trecem la starea urmatoare (readCell).
            OBS: In starea 2 si 3 vom ajunge la fiecare inceput de rand pentru a
            retine randul curent. Pentru celelalte celule din randul respectiv
            nu este nevoie sa mai trecem prin aceste stari deoarece avem deja
            valorile randului curent retinute in vectorul current_row.
* STAREA 4 - readCell: in aceasta stare setam din nou valorile pentru row si col
            pentur a sti exact asupra carei celule din matrice vrem sa facem e-
            xecutia tuturor modificarilor. Vrem sa retinem valoarea celulei in 
            variabila C pe care o vom lua din vectorul current_row deoarece am 
            citit-o in starile precedente pentru a retine tot randul. Index_column
            curent este cel care ne spune la ce element din vector ne referim.
* STAREA 5 - readNorth: Daca ne aflam pe primul rand, atunci vecinii din nord vor
            avea valoarea 0. Altfel, ne uitam la vectorul previous_row la elemen-
            tul corespunzator index-ului de coloana curent (index_column).
* STAREA 6 - readSouth: Pentru vecinii din N avem vectorul previous_row, pentru
            vecinii din E si V avem vectorul current_row, insa pentru cei din S
            trebuie sa mai facem o citire din matrice. Setam row cu randul urmator
            (index_row + 1), col ramane egal cu index-ul de coloana curent (index
            _column) si retinem in variabila S valoarea lui world_in (output-ul
            modulului world).
* STAREA 7 - readWest: Daca ne aflam pe prima coloana, atunci vecinul din vest
            este 0 (W = 0), altfel este valoarea elementului din current_row
            cu index-ul egal cu index_column-1.
* STAREA 8 - readEast: Daca ne aflam pe ultima coloana, atunci vecinul din est
            este 0 (E = 0), altfel este valoarea elementului din current_row
            cu index-ul egal cu index_column+1
* STAREA 9 - writeCell: repetam acelasi lucru ca la reaCell, si anume setam row
            si col pentru a sti la ce celula ne referim. Noua valoare a celulei
            este calculata cu ajutorul vectorului rule primit ca intrare. Fiecare
            bit din rule corespunde cu o configuratie N V C E S. Pentru fiecare 
            celula avem configuratia N V C E S si aflam despre ce bit este vorba 
            din vectorul rule (indexRule). Punem semnalul world_we pe 1 pentru a
            putea scrie in matrice, iar semnalul world_out ia valoarea bitului
            din vectorul rule (rule[indexRule]). Se trece in starea urmatoare
            (increment).
* STAREA 10 - increment: Vrem sa repetam procedeul de citire rand (executat doar
            la prima celula din fiecare rand), de citire vecini si de scriere in
            matrice pentru fiecare celula. Pentru asta avem nevoie sa incrementam
            index-ul de rand si de coloana. In cazul in care pentru randul curent
            nu s-a ajuns la ultima coloana, incrementam doar index-ul de coloana
            si setam next_index_column (next_index_column = index_column + 1).
            Daca index_column == 63, atunci trecem la randul urmator si index-ul
            de coloana devine 0 (next_index_row = index_row + 1). In cazul in care
            am terminat de citit o generatie (index_row == 63 && index_column == 63)
            setam semnalul next_update_done cu 1 si urmatoarea stare va fi cea
            de start pentru a citi urmatoarea generatie.

----------
Observatii
---------- 

1. De precizat este faptul ca se cache-uiesc 2 randuri din lume: un rand la citi-
   rea randului curent (in starile readRow si incrementColumnToReadEntireRow) si 
   cel de-al doilea este citit in momentul in care setam vecinul din sud pentru 
   fiecare celula.
2. Se seteaza starea urmatoare retinuta in next_state, index-ul de rand si de 
   coloana urmator retinut in next_index_row si next_index_column, dar si urma-
   toarea valoare a semnalului update_done retinuta in next_update_done. Acestea
   sunt setate in starile automatului, insa doar pe frontul crescator al clk-ului
   se modifica valorile din state, index_row, index_column.
   De exemplu, pentru a opera asupra aceluiasi rand, nu schimbam next_index_row, 
   insa modificam next_index_column si next_state.
