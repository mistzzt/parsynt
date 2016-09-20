#!/bin/bash

# Pretty-printing helper
msg_fail () {
    echo "FAILED : $1";
}
msg_success () {
    echo "OK : $1"
}
contact () {
    echo "Please report error to victor.nicolet@polytechnique.edu";
    exit
}
sep () {
    echo "----------------------------------------------------------------"
}
echo "Installing Parsynth."
#Check for Racket installation
sep
echo "Checking Racket installation ..."
sep
RACKET_VERSION=$(racket -v | sed -n 's/^.*Racket v\([0-9]*.[0-9]*\).*$/\1/p')
if [ -z $RACKET_VERSION ]
then
    msg_fail "Racket not installed ! Please install Racket."
    exit 0
else
    if [[ $(bc <<< "$RACKET_VERSION > 6.0") ]]
    then
        msg_success "Racket $RACKET_VERSION is installed."
    else
        msg_fail "Racket $RACKET_VERSION is installed, we need at least 6.0."
        echo "Please install a more recent version of Racket."
        exit 0
    fi
fi

echo "Checking installation of Racket components : rosette, c-utils ..."
declare -a REQUIRED_PACKAGES=("rosette" "c-utils")

# Function to query the source of a package. If empty, it means the package
# is not installed in raco.
raco_install_src () {
    eval "raco pkg show $1 | sed -n 's/^\s*$1\s*\([a-ZA-Z\-\s]+[^/][a-zA-Z/_]+\)*/\1/p'"
}

for REQ_PACKAGE in "${REQUIRED_PACKAGES[@]}"
do
    INSTALLATION_SOURCE=$(raco_install_src $REQ_PACKAGE)
    #IF the installation source is empty the package is not installed
    if [[ -z $INSTALLATION_SOURCE ]]
    then
        echo $REQ_PACKAGE "is not installed !"
        echo "Do you want to try to install it automatically using raco ?"
        select yn in "Yes" "No"; do
            case $yn in
                Yes )
                    raco pkg install $REQ_PACKAGE;
                    if [[ -z $(raco_install_src $REQ_PACKAGE) ]]
                    then
                        echo "Failed to install $REQ_PACKAGE automatically."
                        msg_fail "Please install $REQ_PACKAGE manually."
                        exit
                    else
                        break
                    fi;;
                No )
                    echo "Please install $REQ_PACKAGE manually."
                    exit;;
            esac
        done
    else
        msg_success "$REQ_PACKAGE is installed. Source: $INSTALLATION_SOURCE"
    fi
done

# Install the collection in raco
PKG_CONSYNTH='consynth'
CONSYNTH_INSTL_SRC=$(raco_install_src $PKG_CONSYNTH)
if [[ -z $CONSYNTH_INSTL_SRC ]]
then
    echo "Installing local package consynth ..."
    cd consynth;
    # Errors printed come from the fact that the generator uses racket
    # skeletons for the sketches. Probably should think about a better
    # solution ...
    raco pkg install &> /dev/null
    cd ..;
    #Check if the package has been successfully installed
    if [[ -z $(raco_install_src $PKG_CONSYNTH) ]]
    then
        msg_fail "Couldn't install package consynth."
        contact
    else
        msg_success "Package $PKG_CONSYNTH successfully installed!"
    fi
else
    msg_success "Package $PKG_CONSYNTH already present."
fi

msg_success "All Racket components present."
sep
echo "Checking Ocaml components."
sep
# Ocaml version (and if Ocaml is present)
OCAML_VERSION=$(ocaml -vnum)
if [ -z $OCAML_VERSION ]
then
    msg_fail "Ocaml not installed ! Please install Ocaml."
    exit 0
else
    msg_success "Ocaml $OCAML_VERSION is installed."
fi

# Check if OPAM is installed
OPAM_VERSION=$(opam --version)
if [[ -z $OPAM_VERSION ]]
then
    msg_fail "Opam not installed ! We won't install packages automatically."
else
    msg_success "opam $OPAM_VERSION is installed."
fi

# Automatic package installation with OPAM
opam_install () {
	if [[-z $OPAM_VERSION ]]
	then
	   msg_fail "Please installl $1 manually before running the installation script again."
	else
		opam install $1;
		PKG_VERSION=$(opam show $1 | sed -n "s/^\s*version:\s\([0-9]\)*/\1/p")
		if [[ -z $PACKAGE_VERSION ]]
		then
			msg_fail "Failed to install package $1. Please install it manually !"
			exit 0;
		else
			msg_sucess "$1 $PACKAGE_VERSION has been successfully installed."
		fi
	fi
}
# Check for Ocaml packages
# We rely on ocamlfind to find OCaml packages but on OPAM for installation
declare -a OCAML_PACKAGES=("oasis" "cil" "core" "sexplib")

for OCAML_REQ_PACKAGE in "${OCAML_PACKAGES[@]}"
do
	PKG_SRC=$(ocamlfind query $OCAML_REQ_PACKAGE)
	PKG_NOT_FOUND=$(ocamlfind query $OCAML_REQ_PACKAGE | grep 'not found')
	if [[ -z $PKG_NOT_FOUND ]]
	then
		msg_success "Found OCaml package $OCAML_REQ_PACKAGE in $PKG_SRC (ocamlfind)"
	else
		msg_fail "Couldn't find $OCAML_REQ_PACKAGE"
	fi
done

sep
echo "Creating Makefiles for Ocaml sources ..."
sep

cd ./consynth
oasis setup -setup-update dynamic
cd ..
msg_success "Makefiles created, trying make in consynth"
cd consynth
make