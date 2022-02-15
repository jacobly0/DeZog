




                !!!! WARNING FILE STILL TO BE DEVELOPED




----------------------------------------------------------------------------



import {Utility} from '../misc/utility';
import {LabelParserBase, LabelType} from './labelparserbase';


/**
 * This class parses Fasmg EZ80 list files.
 */
export class Fasmgez80LabelParser extends LabelParserBase {

	/**
	 * Parses one line for label and address.
	 * Finds labels at start of the line and labels as EQUs.
	 * Also finds the address of the line.
	 * The function calls addLabelForNumber to add a label or equ and
	 * addAddressLine to add the line and it's address.
	 * @param line The current analyzed line of the list file.
	 */
	/**
	* parseLabelAndAddress(line: string). It is called subsequently for each line of the list file.
	* You need to extract the label and address.
	* I.e. all labels at the start of the line (normally ended by a ":") and all EQUs and their value. 
	* Note: You may omit EQUs if they are too complicated to parse, e.g. if these contain are calculation of other labels.
	* Then call `addLabelForNumber(value: number, label: string)` to associate the label (or EQU) name with the value (address or number). 
	* If your assembler can differentiate local and global labels you should also add the LabelType.	
	* You can have a look at sjasmplus to see how the different types are used. Default is the GLOBAL type.
	* Then if your assembler supports modules you would use NORMAL for your labels and LOCAL if it is a local label (e.g. a label started with a dot '.').
	* If your assembler supports modules than you also need to call moduleStart(name: string) when the module starts and moduleEnd() when it ends.
	* This is required to create correct label names, i.e. the module name is 
	* automatically added to the label name that you pass in addLabelForNumber.
	* To set the number of associated bytes with one address you need to call addAddressLine(address: number, size: number).
	* I.e. in your list file you should parse the address and then count the number of following bytes and pass both to the addAddressLine.
	* Calling this function is necessary to associate the label with the address.
	*/
	protected parseLabelAndAddress(line: string) {

		let countBytes=0;

		// In sjasmplus labels section?
		if (this.sjasmplusLstlabSection) {
			// Format is (no tabs, only spaces, 'X'=used, without X the label is not used):
			// 0x60DA X TestSuite_ClearScreen.UT_clear_screen
			// 0x0008   BLUE
			if (!line.startsWith('0x'))
				return;
			// Get hex value
			const valString=line.substr(2, 4);
			const value=parseInt(valString, 16);
			// Label
			const label=line.substr(9).trim();
			// Add label
			this.addLabelForNumber(value, label, LabelType.GLOBAL);	// Full labels
			// Throw line away
			this.listFile.pop();
			return;
		}

		// Check for sjasmplus "--lstlab" section
		if (line.startsWith("Value")) {
			// The end of the sjasmplus list file has been reached
			// where the labels start.
			this.sjasmplusLstlabSection=true;
			// Throw line away
			this.listFile.pop();
			return;
		}

		// Replace line number with empty string.
		line=line.replace(this.sjasmRegEx, '');

		// Check if valid line (not "~")
		// Search for "~". E.g. "8002 ~            Level   defw 4"
		const invalidMatch=this.invalidLineRegEx.exec(line);
		if (invalidMatch)
			return;	// Skip line.

		// Extract address.
		let address=parseInt(line.substr(0, 4), 16);
		if (isNaN(address)) // isNaN if e.g. the first line: "# File main.asm"
			address=undefined!;
		if (address!=undefined) {
			// Check for MODULE
			var matchModuleStart=this.matchModuleStartRegEx.exec(line);
			if (matchModuleStart) {
				// Push module to stack
				const moduleName=matchModuleStart[1];
				this.moduleStart(moduleName);
			}
			else {
				// End
				var matchModuleEnd=this.matchModuleEndRegEx.exec(line);
				if (matchModuleEnd) {
					// Remove module from stack
					this.moduleEnd();
				}
			}

			// Check for labels and "equ". It allows also for @/dot notation as used in sjasmplus.
			const match=this.labelRegEx.exec(line);
			if (match) {
				let label=match[2];
				let labelType=LabelType.NORMAL;
				// Check for local label
				if (label.startsWith('.'))
					labelType=LabelType.LOCAL;
				// Check for global label
				const global=match[1];
				if (global!='')
					labelType=LabelType.GLOBAL;
				const equ=match[3];
				if (equ) {
					if (equ.toLowerCase().startsWith('equ')) {
						// EQU: add to label array
						let valueString=match[4];
						// Only try a simple number conversion, e.g. no label arithmetic (only already known labels)
						try {
							// Check for any '$', i.e. current address
							if (valueString.indexOf('$')>=0) {
								// Replace $ with current address
								const addressString=address.toString();
								const cAddrString=valueString.replace(/(?<![a-z_0-9\$])\$(?![a-z_0-9\$])/i, addressString);
								valueString=cAddrString;
							}
							// Evaluate
							const value=Utility.evalExpression(valueString, false);
							//const entry = { value, file: fileName, line: lineNr};
							// Add EQU
							this.addLabelForNumber(value, label, labelType);
						}
						catch {};	// do nothing in case of an error
					}
				}
				else {
					// Add label
					this.addLabelForNumber(address, label, labelType);
				}
			}

			// Search for bytes after the address:
			//line = "80F1 D5 C5";
			const matchBytes=this.matchBytesRegEx.exec(line);
			// Count how many bytes are included in the line.
			if (matchBytes) {
				const bytes=matchBytes[1].trim();
				const lenBytes=bytes.length;
				countBytes=0;
				for (let k=0; k<lenBytes; k++) {
					// Count all characters (chars are hex, so 2 characters equal to 1 byte)
					if (bytes.charCodeAt(k)>32)
						countBytes++;
				}
				// 2 characters = 1 byte
				countBytes/=2;
			}
		}

		// Store address (or several addresses for one line).
		// This needs to be called even if address is undefined.
		this.addAddressLine(address, countBytes);

	}


	/**
	 * Parses one line for current file name and line number in this file.
	 * The function determines the line number from the list file.
	 * The line number is the line number in the correspondent source file.
	 * Note: this is not the line number of the list file.
	 * The list file may include other files. It's the line number of those files we are after.
	 * Call 'setLineNumber' with the line number to set it. Note that source file numbers start at 0.
	 * Furthermore it also determines teh beginning and ending of include files.
	 * Call 'includeStart(fname)' and 'includeEnd()'.
	 * @param line The current analyzed line of the listFile array.
	 */
	 /**
	 * In the second pass the file names and line numbers are associated with the addresses.
	 * This is done in parseAllFilesAndLineNumbers. 
	 * It calls parseFileAndLineNumber(line: string) for each line.
	 * parseFileAndLineNumber(line: string) has to determine the include file start and end by
	 * calling includeStart(fname) and includeEnd().
	 * And it has to determine the line number in the file.
	 * Note: this is not the line number of the list file. The list file may include other files.
	 * It's the line number of those files we are after.
	 * Call 'setLineNumber' with the line number to set it. Note that source file numbers start at 0.
     */
	protected parseFileAndLineNumber(line: string) {

		// Check for start of include file
		if (line.startsWith('# file opened:')) {
			// Get file name
			const fname=line.substr(15).trim();
			// Include file
			this.includeStart(fname);
			return;
		}

		// Check for end of include file
		if (line.startsWith('# file closed:')) {
			// Include ended.
			this.includeEnd();
			return;
		}

		// Get line number
		const matchLineNumber=this.matchLineNumberRegEx.exec(line);
		if (!matchLineNumber)
			return;	// sjasmplus contains lines without line number.
		const lineNumber=parseInt(matchLineNumber[1]);

		// Associate with line number
		this.setLineNumber(lineNumber-1);	// line numbers start at 0

	}

}
