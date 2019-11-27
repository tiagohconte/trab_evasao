#!/bin/bash
#Nomeação de variáveis com arquivos externos
DIREVASAO=evasao/
ARQEVASAO=evasao.csv
ARQRANK=ranking.txt
ARQANOS=anos.txt

if [ -d $DIREVASAO ]; #Verifica se existe o diretório com as informações de evasão
then
	ARQUIVOS=$(ls $DIREVASAO)   #Monta variável com o nome dos arquivos de evasão
else							
	echo "Pasta de arquivos de evasão não encontrada!" #Caso o diretório não exista, o script para
	exit
fi

if [ -a $ARQEVASAO ]; #Verificação de existência de arquivos com mesmo nome dos que serão criados mais tarde
then
	rm $ARQEVASAO	#Caso existam, os arquivos serão removidos
fi

if [ -a $ARQRANK ];
then
	rm $ARQRANK
fi

if [ -a $ARQANOS ];
then
	rm $ARQANOS
fi

echo "ANO	EVASÕES" > ano-num.dat

for i in $ARQUIVOS;   #Leitura dos arquivos de evasão (ITEM 1)
do
	tail -n +2 $DIREVASAO$i >> $ARQEVASAO 		#Concatenação dos arquivos em único arquivo (ITEM 2)

	#PREPARAÇÃO DE DADOS PARA USO FUTURO

	ANO_DADOS=${i#evasao-} && ANO_DADOS=${ANO_DADOS%.csv}		#Coleta do ano das evasões em análise
	ANOS_INGRESSO=$(tail -n +2 evasao/$i | cut -d, -f4 | sort -nru)		#Anos em que os estudantes ingressaram
	for j in $ANOS_INGRESSO;
	do
		ANOS=$(($ANO_DADOS-$j))										#Calculo dos anos até a evasão
		QUANT_ALUNOS=$(tail -n +2 evasao/$i | cut -d, -f4 | grep -c $j)	#Quantidade de alunos com o tempo calculado
		echo -e $ANOS"ANOS "$QUANT_ALUNOS >> $ARQANOS					#Insere informações no arquivo auxiliar

	done

	QUANT_ALUNOS=$(tail -n +2 evasao/$i | wc -l)			#Coleta de dados para elaboração do gráfico do Item 7
	echo $ANO_DADOS" "$QUANT_ALUNOS >> ano-num.dat

done

FORMAS_INGRESSO=$(cat $ARQEVASAO | cut -d, -f3 | sort -u)		#Preparação de variável para uso futuro

IFS=$'\n'
TIPOS=$(cat $ARQEVASAO | cut -d, -f1 | sort -u)			#Coleta os tipos de evasão

#ITEM 3 - RANKING FORMA DE EVASÃO

for i in $TIPOS;
do
	FREQ=$(grep -c $i $ARQEVASAO)						#Coleta a frequência de cada tipo de evasão
	echo -e $FREQ"="$i"\n" >> $ARQRANK
done

RANK=$(cat $ARQRANK | sort -nr)			#Ordena o ranking em forma decrescente
rm $ARQRANK

echo -e "[ITEM 3]\n"
for i in $RANK;										#Imprime o ranking
do
	TIPO_EVASAO=$(echo $i | cut -d= -f2)
	FREQ=$(echo $i | cut -d= -f1)
	echo -e $TIPO_EVASAO" "$FREQ
done

#ITEM 4 - ANOS

ANOS=$(cat $ARQANOS | cut -d" " -f1 | sort -nu)		#Coleta os anos até a evasão do arquivo previamente organizado
echo -e "\n[ITEM 4]\n"								
echo -e "ALUNOS  ANOS\n"
for i in $ANOS;
do
	QUANT_ALUNOS=$(grep -w $i $ARQANOS | cut -d" " -f2 | awk '{s+=$1} END {printf "%.0f\n", s}')	#Soma as ocorrências
	echo -e $QUANT_ALUNOS"	"${i%ANOS}
done
rm $ARQANOS

#ITEM 5 - SEMESTRES

echo -e "\n[ITEM 5]\n"

for i in $ARQUIVOS;   #Leitura dos arquivos de evasão
do
	ANO_DADOS=${i#evasao-} && ANO_DADOS=${ANO_DADOS%.csv}
	OCORR_PRIMEIRO=$(grep -c "1o. Semestre" $DIREVASAO$i)
	OCORR_SEGUNDO=$(grep -c "2o. Semestre" $DIREVASAO$i)
	TOTAL_EVASOES_ANO=$(($(wc -l $DIREVASAO$i | cut -d" " -f1)-1))
	if [ $OCORR_PRIMEIRO -gt $OCORR_SEGUNDO ]
	then
		PORC=$((($OCORR_PRIMEIRO*100)/$TOTAL_EVASOES_ANO))
		echo -e $ANO_DADOS"	semestre 1 - "$PORC"%"
	else
		PORC=$((($OCORR_SEGUNDO*100)/$TOTAL_EVASOES_ANO))
		echo -e $ANO_DADOS"	semestre 2 - "$PORC"%"
	fi

done

#ITEM 6 - SEXO

echo -e "\n[ITEM 6]\n"

MASC=$(cat $ARQEVASAO | cut -d, -f5 | grep -c "M")
FEM=$(cat $ARQEVASAO | cut -d, -f5 | grep -c "F")
TOTAL_EVASOES=$(wc -l $ARQEVASAO | cut -d" " -f1)
PORC_MASC=$((($MASC*100)/$TOTAL_EVASOES))
PORC_FEM=$((($FEM*100)/$TOTAL_EVASOES))

echo "SEXO	MÉDIA DE EVASÕES (5 anos)"
echo -e "F		"$PORC_FEM"%\nM		"$PORC_MASC"%"

#ITEM 7 - EVASÕES POR ANO

echo -e 'set term png
reset
set title "NÚMERO DE EVASÕES POR ANO"
set key autotitle columnhead
set xtics 1
set xlabel "Ano"
set ylabel "Evasão"
set term png size 800,600
set output "evasoes-ano.png"
plot "ano-num.dat" using 1:2 w lines lw 2' > grafico.gp

gnuplot -e "load 'grafico.gp'"

#ITEM 8 - EVASÕES POR TIPO DE INGRESSO

echo -n "ANOS" > formas_ing.dat
for i in $FORMAS_INGRESSO;
do
	echo -n "?"$i >> formas_ing.dat
done

for i in $ARQUIVOS;
do
	ANO_DADOS=${i#evasao-} && ANO_DADOS=${ANO_DADOS%.csv}		#Coleta do ano
	echo -ne "\n"$ANO_DADOS >> formas_ing.dat

	for j in $FORMAS_INGRESSO;
	do
		QUANT_ALUNOS=$(grep -c $j $DIREVASAO$i)
		echo -n "?"$QUANT_ALUNOS >> formas_ing.dat
	done	
done

echo -ne 'set term png
reset
set title "NÚMERO DE EVASÕES POR FORMA DE INGRESSO"
set key autotitle columnhead
set style data histogram
set style histogram cluster gap 1
set style fill solid border -1
set xlabel "Ano"
set ylabel "Evasão"
set ytics nomirror
set xtics nomirror
set datafile separator "?"
set term png size 1200,600
set output "evasoes-forma.png"
plot "formas_ing.dat" using 2:xtic(1), '\'\'' u 3, '\'\'' u 4, '\'\'' u 5 lc rgb "gray", '\'\'' u 6, '\'\'' us 7, '\'\'' u 8, '\'\'' u 9, '\'\'' u 10 lc rgb "white", '\'\'' u 11 lc rgb "orange"' > grafico.gp

gnuplot -e "load 'grafico.gp'"

rm grafico.gp
rm ano-num.dat
rm formas_ing.dat