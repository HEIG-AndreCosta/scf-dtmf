correlation_divide_inst : correlation_divide PORT MAP (
		clock	 => clock_sig,
		denom	 => denom_sig,
		numer	 => numer_sig,
		quotient	 => quotient_sig,
		remain	 => remain_sig
	);
