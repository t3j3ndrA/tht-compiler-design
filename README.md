# THT Language - Compiler design project

## Dharmsinh Desai University | Information Technology | Sem-6

<hr>

## Developers

- IT002 - Baxi Triparna
- IT003 - Dhanani Tejendra
- IT004 - Harsh Gondaliya

<hr>

## How to generate executable file ?

<pre>
flex tht.l
bison -dy tht.y
gcc lex.yy.c y.tab.c -o tht.exe
</pre>

<hr>

## How to run ?

### Windows

in cmd :

<pre>
tht.exe
</pre>

### Linux

in terminal :

<pre>
./tht.out
</pre>

<hr>

## Sample Programs

<pre>
print "Hello World!";
exit;
</pre>

<pre>
print 4>=3;
exit;
</pre>

<pre>
{print "5 is greather than 4 = "; print 5>4; }
exit;
</pre>
