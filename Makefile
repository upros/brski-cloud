DRAFT:=brski-cloud
VERSION:=$(shell ./getver ${DRAFT}.mkd )
#YANGDATE=2020-01-06
#YANGFILE=yang/ietf-delegated-voucher@${YANGDATE}.yang
#PYANG=pyang
#EXAMPLES=ietf-delegated-voucher-tree.txt
#EXAMPLES+=${YANGFILE}

${DRAFT}-${VERSION}.txt: ${DRAFT}.txt
	cp ${DRAFT}.txt ${DRAFT}-${VERSION}.txt
	: git add ${DRAFT}-${VERSION}.txt ${DRAFT}.txt

%.xml: %.mkd ${EXAMPLES}
	kramdown-rfc2629 ${DRAFT}.mkd >${DRAFT}.v2.xml
	xml2rfc --v2v3 ${DRAFT}.v2.xml && mv ${DRAFT}.v2v3.xml ${DRAFT}.xml
	: git add ${DRAFT}.xml

%.txt: %.xml
	unset DISPLAY; XML_LIBRARY=$(XML_LIBRARY):./src xml2rfc $? $@

%.html: %.xml
	unset DISPLAY; XML_LIBRARY=$(XML_LIBRARY):./src xml2rfc --html -o $@ $?

submit: ${DRAFT}.xml
	curl -S -F "user=mcr+ietf@sandelman.ca" -F "xml=@${DRAFT}.xml;type=application/xml" https://datatracker.ietf.org/api/submit

version:
	echo Version: ${VERSION}

clean:
	-rm -f ${DRAFT}.xml

.PRECIOUS: ${DRAFT}.xml
