extends RefCounted
## Device-local accounts. Passwords are salted PBKDF2-HMAC-SHA256 verifiers.
const ITERATIONS := 100000
var directory := "user://haven_accounts"
func key_for(name: String) -> String:
	return name.strip_edges().to_lower().sha256_text()
func progress_path(name: String) -> String:
	return directory.path_join(key_for(name) + ".save.cfg")
func credential_path(name: String) -> String:
	return directory.path_join(key_for(name) + ".account.cfg")
func derive(password: String, salt: PackedByteArray) -> PackedByteArray:
	var crypto := Crypto.new()
	var block := salt.duplicate()
	block.append_array(PackedByteArray([0, 0, 0, 1]))
	var secret := password.to_utf8_buffer()
	var u := crypto.hmac_digest(HashingContext.HASH_SHA256, secret, block)
	var result := u.duplicate()
	for round_id in range(1, ITERATIONS):
		u = crypto.hmac_digest(HashingContext.HASH_SHA256, secret, u)
		for i in range(32): result[i] = result[i] ^ u[i]
	return result
func create_account(name: String, password: String) -> String:
	name = name.strip_edges()
	if name.length() < 3 or name.length() > 18: return "Choose a username with 3–18 characters."
	if password.length() < 8 or password.length() > 128: return "Use a password with 8–128 characters."
	if FileAccess.file_exists(credential_path(name)): return "That username already exists on this computer. Sign in instead."
	if FileAccess.file_exists(progress_path(name)): return "A saved profile already uses that username. Restore its account file or choose another name."
	if DirAccess.make_dir_recursive_absolute(directory) != OK: return "Cannot create the account folder. Check disk permissions."
	var config := ConfigFile.new()
	var salt := Crypto.new().generate_random_bytes(16)
	config.set_value("account", "name", name)
	config.set_value("account", "salt", salt.hex_encode())
	config.set_value("account", "verifier", derive(password, salt).hex_encode())
	config.set_value("account", "iterations", ITERATIONS)
	if config.save(credential_path(name)) != OK: return "Could not save your account. Check available disk space."
	return ""
func verify(name: String, password: String) -> String:
	if password.length() > 128: return "Incorrect username or password."
	var config := ConfigFile.new()
	if config.load(credential_path(name)) != OK: return "Incorrect username or password."
	var salt := str(config.get_value("account", "salt", "")).hex_decode()
	var expected := str(config.get_value("account", "verifier", "")).hex_decode()
	if salt.size() != 16 or expected.size() != 32: return "This account file is damaged. Restore it from a backup."
	if not Crypto.new().constant_time_compare(derive(password, salt), expected): return "Incorrect username or password."
	return ""
