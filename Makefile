INC_DIR = ./
CXX		=g++
LD		=g++
CXXFLAGS	=-O2 -ggdb -std=gnu++0x -Wall
LDFLAGS		=-lz -lm
SOFLAGS		=-fPIC -shared 
SHELL		=bash
###
SrcSuf        = cpp
HeadSuf       = h
ObjSuf        = o
DepSuf        = d
DllSuf        = so
StatSuf       = a

## Packages	=controller testDataTypeServer testDataTypeClient testDataType testXMLLib testUInt
## Objects		=Daemon EventBuilder Handler Logger Profiler  Configurator ControlManager ConnectionManager Utility HwManager AsyncUtils BoardConfig

CppTestFiles=$(wildcard test/*.$(SrcSuf))
Packages=$(patsubst test/%.$(SrcSuf),%,$(CppTestFiles) )

CppSrcFiles=$(wildcard src/*.$(SrcSuf))
Objects=$(patsubst src/%.$(SrcSuf),%,$(CppSrcFiles))

LibName		=H4LySO

### ----- OPTIONS ABOVE ----- ####

#InfoLine = \033[01\;31m compiling $(1) \033[00m
InfoLine = compiling $(1)

BASEDIR=$(shell pwd)
BINDIR=$(BASEDIR)/bin
SRCDIR = $(BASEDIR)/src
HDIR = $(BASEDIR)/include

### Main Target, first
.PHONY: all
all: info $(Packages) | $(BINDIR)

CXXFLAGS	+=`root-config --cflags`
LDFLAGS 	+=`root-config --libs`

BINOBJ	=$(patsubst %,$(BINDIR)/%.$(ObjSuf),$(Objects) )
SRCFILES=$(patsubst %,$(SRCDIR)/%.$(SrcSuf),$(Objects) )
HFILES	=$(patsubst %,$(HDIR)/%.$(HeadSuf),$(Objects) )
StatLib		=$(BINDIR)/H4LySO.$(StatSuf)
SoLib		=$(BINDIR)/H4LySO.$(DllSuf)

.PRECIOUS:*.ObjSuf *.DepSuf *.DllSuf

Deps=$(patsubst %,$(BINDIR)/%.$(DepSuf),$(Objects) $(Packages) )

############### EXPLICIT RULES ###############

$(BINDIR):
	mkdir -p $(BINDIR)

info:
	@echo "--------------------------"
	@echo "Compile on $(shell hostname)"
	@echo "Packages are: $(Packages)"
	@echo "Objects are: $(Objects)"
	@echo "--------------------------"
	@echo "DEBUG:"

$(StatLib): $(BINOBJ)
	ar rcs $@ $(BINOBJ)
.PHONY: soLib
soLib: $(SoLib)

$(SoLib): $(StatLib)
	$(LD) $(LDFLAGS) $(SOFLAGS) -o $@ $^

.PHONY: $(Packages) 
$(Packages): % : $(BINDIR)/% | $(BINDIR)
	@echo $(call InfoLine , $@ )

#$(BINDIR)/$(Packages): $(BINDIR)/% : $(BASEDIR)/test/%.$(SrcSuf) $(StatLib) | $(BINDIR)
$(addprefix $(BINDIR)/,$(Packages)): $(BINDIR)/% : $(BASEDIR)/test/%.$(SrcSuf) $(StatLib) | $(BINDIR)
	@echo $(call InfoLine , $@ )
	$(CXX) $(LDFLAGS) $(CXXFLAGS) -o $@ $< $(StatLib) -I$(INC_DIR) -I$(HDIR)

#make this function of $(Packages)
#.PHONY: controller
#controller: bin/controller
#bin/controller: test/controller.cpp $(BINOBJ) $(StatLib)
#	$(CXX) $(CXXFLAGS) $(LDFLAGS) -o $@ $(BINOBJ) $< 


.PHONY: clean
clean:
	-rm -v bin/*.$(ObjSuf)
	-rm -v bin/*.$(DllSuf)
	-rm -v bin/*.$(StatSuf)


############### IMPLICIT RULES ###############



#.o
%.$(ObjSuf): $(BINDIR)/%.$(ObjSuf)

#.o
$(BINDIR)/%.$(ObjSuf): $(SRCDIR)/%.$(SrcSuf) $(HDIR)/%.$(HeadSuf)
	@echo $(call InfoLine , $@ )
	$(CXX) $(CXXFLAGS) $(LDFLAGS) -c -o $@ $(SRCDIR)/$*.$(SrcSuf) -I$(INC_DIR) -I$(HDIR)

#.d
$(BINDIR)/%.$(DepSuf): $(SRCDIR)/%.$(SrcSuf) $(HDIR)/%.$(HeadSuf)
	@echo $(call InfoLine , $@ )
	$(CXX) $(CXXFLAGS) $(LDFLAGS) -M -o $@ $(SRCDIR)/$*.$(SrcSuf) -I$(INC_DIR) -I$(HDIR)
	sed -i'' "s|^.*:|& Makefile $(BINDIR)/&|g" $@

#-include $(Deps)
#	%.d: %.c
#		$(SHELL) -ec '$(CC) -M \
#			$(CPPFLAGS) $< | \
#			sed '\''s/$*.o/& $@/g'\'' \
#			> $@'
#	
