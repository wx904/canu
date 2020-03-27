
###############################################################################
 #
 #  This file is part of canu, a software program that assembles whole-genome
 #  sequencing reads into contigs.
 #
 #  This software is based on:
 #    'Celera Assembler' r4587 (http://wgs-assembler.sourceforge.net)
 #    the 'kmer package' r1994 (http://kmer.sourceforge.net)
 #
 #  Except as indicated otherwise, this is a 'United States Government Work',
 #  and is released in the public domain.
 #
 #  File 'README.licenses' in the root directory of this distribution
 #  contains full conditions and disclaimers.
 ##

package canu::Output;

require Exporter;

@ISA    = qw(Exporter);
@EXPORT = qw(generateOutputs);

use strict;
use warnings "all";
no  warnings "uninitialized";

use File::Copy;

use canu::Defaults;
use canu::Execution;

use canu::Report;

use canu::Grid_Cloud;



sub generateOutputs ($) {
    my $asm     = shift @_;
    my $bin     = getBinDirectory();
    my $cmd;

    my $type    = "fasta";  #  Should probably be an option.

    #  Layouts

    if (! fileExists("$asm.contigs.layout")) {
        fetchFile("unitigging/$asm.ctgStore/seqDB.v002.dat");
        fetchFile("unitigging/$asm.ctgStore/seqDB.v002.tig");

        if (-e "unitigging/$asm.ctgStore/seqDB.v002.tig") {
            $cmd  = "$bin/tgStoreDump \\\n";
            $cmd .= "  -S ./$asm.seqStore \\\n";
            $cmd .= "  -T ./unitigging/$asm.ctgStore 2 \\\n";
            $cmd .= "  -o ./$asm.contigs \\\n";
            $cmd .= "  -layout \\\n";
            $cmd .= "> ./$asm.contigs.layout.err 2>&1";

            if (runCommand(".", $cmd)) {
                caExit("failed to output contig layouts", "$asm.contigs.layout.err");
            }

            unlink "$asm.contigs.layout.err";
        } else {
            touch("$asm.contigs.layout");
        }

        stashFile("$asm.contigs.layout");
    }

    if (! fileExists("$asm.unitigs.layout")) {
        fetchFile("unitigging/$asm.utgStore/seqDB.v001.dat");   #  Why is this needed?
        fetchFile("unitigging/$asm.utgStore/seqDB.v001.tig");

        fetchFile("unitigging/$asm.utgStore/seqDB.v002.dat");
        fetchFile("unitigging/$asm.utgStore/seqDB.v002.tig");

        if (-e "unitigging/$asm.utgStore/seqDB.v002.tig") {
            $cmd  = "$bin/tgStoreDump \\\n";
            $cmd .= "  -S ./$asm.seqStore \\\n";
            $cmd .= "  -T ./unitigging/$asm.utgStore 2 \\\n";
            $cmd .= "  -o ./$asm.unitigs \\\n";
            $cmd .= "  -layout \\\n";
            $cmd .= "> ./$asm.unitigs.layout.err 2>&1";

            if (runCommand(".", $cmd)) {
                caExit("failed to output unitig layouts", "$asm.unitigs.layout.err");
            }

            unlink "$asm.unitigs.layout.err";
        } else {
            touch("$asm.unitigs.layout");
        }

        stashFile("$asm.unitigs.layout");
    }

    #  Sequences

    foreach my $tt ("unassembled", "contigs") {
        if (! fileExists("$asm.$tt.$type")) {
            fetchFile("unitigging/$asm.ctgStore/seqDB.v002.dat");
            fetchFile("unitigging/$asm.ctgStore/seqDB.v002.tig");

            if (-e "unitigging/$asm.ctgStore/seqDB.v002.tig") {
                $cmd  = "$bin/tgStoreDump \\\n";
                $cmd .= "  -S ./$asm.seqStore \\\n";
                $cmd .= "  -T ./unitigging/$asm.ctgStore 2 \\\n";
                $cmd .= "  -consensus -$type \\\n";
                $cmd .= "  -$tt \\\n";
                $cmd .= "> ./$asm.$tt.$type\n";
                $cmd .= "2> ./$asm.$tt.err";

                if (runCommand(".", $cmd)) {
                    caExit("failed to output $tt consensus sequences", "$asm.$tt.err");
                }

                unlink "$asm.$tt.err";
            } else {
                touch("$asm.$tt.$type");
            }

            stashFile("$asm.$tt.$type");
        }
    }

    if (! fileExists("$asm.unitigs.$type")) {
        fetchFile("unitigging/$asm.utgStore/seqDB.v002.dat");
        fetchFile("unitigging/$asm.utgStore/seqDB.v002.tig");

        if (-e "unitigging/$asm.utgStore/seqDB.v002.tig") {
            $cmd  = "$bin/tgStoreDump \\\n";
            $cmd .= "  -S ./$asm.seqStore \\\n";
            $cmd .= "  -T ./unitigging/$asm.utgStore 2 \\\n";
            $cmd .= "  -consensus -$type \\\n";
            $cmd .= "  -contigs \\\n";
            $cmd .= "> ./$asm.unitigs.$type\n";
            $cmd .= "2> ./$asm.unitigs.err";

            if (runCommand(".", $cmd)) {
                caExit("failed to output unitig consensus sequences", "$asm.unitigs.err");
            }

            unlink "$asm.unitigs.err";
        } else {
            touch("$asm.unitigs.$type");
        }

        stashFile("$asm.unitigs.$type");
    }

    #  Graphs

    if (!fileExists("$asm.unitigs.gfa")) {
        fetchFile("unitigging/4-unitigger/$asm.unitigs.aligned.gfa");

        if (-e "unitigging/4-unitigger/$asm.unitigs.aligned.gfa") {
            copy("unitigging/4-unitigger/$asm.unitigs.aligned.gfa", "$asm.unitigs.gfa");
        } else {
            touch("$asm.unitigs.gfa");
        }

        stashFile("$asm.unitigs.gfa");
    }

    if (!fileExists("$asm.unitigs.bed")) {
        fetchFile("unitigging/4-unitigger/$asm.unitigs.aligned.bed");

        if (-e "unitigging/4-unitigger/$asm.unitigs.aligned.bed") {
            copy("unitigging/4-unitigger/$asm.unitigs.aligned.bed", "$asm.unitigs.bed");
        } else {
        }

        stashFile("$asm.unitigs.bed");
    }

  finishStage:
    generateReport($asm);
    resetIteration("generateOutputs");

  allDone:
    print STDERR "--\n";
    print STDERR "-- Assembly '", getGlobal("onExitNam"), "' finished in '", getGlobal("onExitDir"), "'.\n";
    print STDERR "--\n";
    print STDERR "-- Summary saved in '$asm.report'.\n";
    print STDERR "--\n";
    print STDERR "-- Sequences saved:\n";
    print STDERR "--   Contigs       -> '$asm.contigs.$type'\n";
    print STDERR "--   Unassembled   -> '$asm.unassembled.$type'\n";
    print STDERR "--   Unitigs       -> '$asm.unitigs.$type'\n";
    print STDERR "--\n";
    print STDERR "-- Read layouts saved:\n";
    print STDERR "--   Contigs       -> '$asm.contigs.layout'.\n";
    print STDERR "--   Unitigs       -> '$asm.unitigs.layout'.\n";
    print STDERR "--\n";
    print STDERR "-- Graphs saved:\n";
    print STDERR "--   Unitigs       -> '$asm.unitigs.gfa'.\n";
}
