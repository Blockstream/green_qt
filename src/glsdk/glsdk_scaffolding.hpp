#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#ifndef UNIFFI_CPP_INTERNALSTRUCTS
#define UNIFFI_CPP_INTERNALSTRUCTS
struct ForeignBytes {
    int32_t len;
    uint8_t *data;
};

struct RustBuffer {
    uint64_t capacity;
    uint64_t len;
    uint8_t *data;
};

struct RustCallStatus {
    int8_t code;
    RustBuffer error_buf;
};

#endif
struct UniffiVTableCallbackInterfaceLogListener {
    void * on_log;
    void * uniffi_free;
};
struct UniffiVTableCallbackInterfaceNodeEventListener {
    void * on_event;
    void * uniffi_free;
};
void * uniffi_glsdk_fn_clone_config(void * ptr, RustCallStatus *out_status);
void uniffi_glsdk_fn_free_config(void * ptr, RustCallStatus *out_status);
void * uniffi_glsdk_fn_constructor_config_new(RustCallStatus *out_status);
void * uniffi_glsdk_fn_method_config_with_developer_cert(void * ptr, void * cert, RustCallStatus *out_status);
void * uniffi_glsdk_fn_method_config_with_network(void * ptr, RustBuffer network, RustCallStatus *out_status);
void * uniffi_glsdk_fn_clone_credentials(void * ptr, RustCallStatus *out_status);
void uniffi_glsdk_fn_free_credentials(void * ptr, RustCallStatus *out_status);
void * uniffi_glsdk_fn_constructor_credentials_load(RustBuffer raw, RustCallStatus *out_status);
RustBuffer uniffi_glsdk_fn_method_credentials_node_id(void * ptr, RustCallStatus *out_status);
RustBuffer uniffi_glsdk_fn_method_credentials_save(void * ptr, RustCallStatus *out_status);
void * uniffi_glsdk_fn_clone_developercert(void * ptr, RustCallStatus *out_status);
void uniffi_glsdk_fn_free_developercert(void * ptr, RustCallStatus *out_status);
void * uniffi_glsdk_fn_constructor_developercert_new(RustBuffer cert, RustBuffer key, RustCallStatus *out_status);
void * uniffi_glsdk_fn_clone_handle(void * ptr, RustCallStatus *out_status);
void uniffi_glsdk_fn_free_handle(void * ptr, RustCallStatus *out_status);
void uniffi_glsdk_fn_method_handle_stop(void * ptr, RustCallStatus *out_status);
void * uniffi_glsdk_fn_clone_node(void * ptr, RustCallStatus *out_status);
void uniffi_glsdk_fn_free_node(void * ptr, RustCallStatus *out_status);
RustBuffer uniffi_glsdk_fn_method_node_credentials(void * ptr, RustCallStatus *out_status);
void uniffi_glsdk_fn_method_node_disconnect(void * ptr, RustCallStatus *out_status);
RustBuffer uniffi_glsdk_fn_method_node_generate_diagnostic_data(void * ptr, RustCallStatus *out_status);
RustBuffer uniffi_glsdk_fn_method_node_get_info(void * ptr, RustCallStatus *out_status);
RustBuffer uniffi_glsdk_fn_method_node_list_funds(void * ptr, RustCallStatus *out_status);
RustBuffer uniffi_glsdk_fn_method_node_list_invoices(void * ptr, RustBuffer label, RustBuffer invstring, RustBuffer payment_hash, RustBuffer offer_id, RustBuffer index, RustBuffer start, RustBuffer limit, RustCallStatus *out_status);
RustBuffer uniffi_glsdk_fn_method_node_list_payments(void * ptr, RustBuffer req, RustCallStatus *out_status);
RustBuffer uniffi_glsdk_fn_method_node_list_pays(void * ptr, RustBuffer bolt11, RustBuffer payment_hash, RustBuffer status, RustBuffer index, RustBuffer start, RustBuffer limit, RustCallStatus *out_status);
RustBuffer uniffi_glsdk_fn_method_node_list_peer_channels(void * ptr, RustCallStatus *out_status);
RustBuffer uniffi_glsdk_fn_method_node_list_peers(void * ptr, RustCallStatus *out_status);
RustBuffer uniffi_glsdk_fn_method_node_lnurl_pay(void * ptr, RustBuffer request, RustCallStatus *out_status);
RustBuffer uniffi_glsdk_fn_method_node_lnurl_withdraw(void * ptr, RustBuffer request, RustCallStatus *out_status);
RustBuffer uniffi_glsdk_fn_method_node_node_state(void * ptr, RustCallStatus *out_status);
RustBuffer uniffi_glsdk_fn_method_node_onchain_balance_state(void * ptr, RustCallStatus *out_status);
RustBuffer uniffi_glsdk_fn_method_node_onchain_fee_rates(void * ptr, RustCallStatus *out_status);
RustBuffer uniffi_glsdk_fn_method_node_onchain_receive(void * ptr, RustCallStatus *out_status);
RustBuffer uniffi_glsdk_fn_method_node_onchain_send(void * ptr, RustBuffer destination, RustBuffer amount_or_all, RustBuffer sat_per_vbyte, RustBuffer utxos, RustCallStatus *out_status);
RustBuffer uniffi_glsdk_fn_method_node_prepare_onchain_send(void * ptr, RustBuffer destination, RustBuffer amount_or_all, RustBuffer sat_per_vbyte, RustCallStatus *out_status);
RustBuffer uniffi_glsdk_fn_method_node_receive(void * ptr, RustBuffer label, RustBuffer description, RustBuffer amount_msat, RustCallStatus *out_status);
RustBuffer uniffi_glsdk_fn_method_node_send(void * ptr, RustBuffer invoice, RustBuffer amount_msat, RustCallStatus *out_status);
void uniffi_glsdk_fn_method_node_stop(void * ptr, RustCallStatus *out_status);
void * uniffi_glsdk_fn_method_node_stream_node_events(void * ptr, RustCallStatus *out_status);
void * uniffi_glsdk_fn_clone_nodebuilder(void * ptr, RustCallStatus *out_status);
void uniffi_glsdk_fn_free_nodebuilder(void * ptr, RustCallStatus *out_status);
void * uniffi_glsdk_fn_constructor_nodebuilder_new(void * config, RustCallStatus *out_status);
void * uniffi_glsdk_fn_method_nodebuilder_connect(void * ptr, RustBuffer credentials, RustBuffer mnemonic, RustCallStatus *out_status);
void * uniffi_glsdk_fn_method_nodebuilder_recover(void * ptr, RustBuffer mnemonic, RustCallStatus *out_status);
void * uniffi_glsdk_fn_method_nodebuilder_register(void * ptr, RustBuffer mnemonic, RustBuffer invite_code, RustCallStatus *out_status);
void * uniffi_glsdk_fn_method_nodebuilder_register_or_recover(void * ptr, RustBuffer mnemonic, RustBuffer invite_code, RustCallStatus *out_status);
void * uniffi_glsdk_fn_method_nodebuilder_with_event_listener(void * ptr, uint64_t listener, RustCallStatus *out_status);
void * uniffi_glsdk_fn_clone_nodeeventstream(void * ptr, RustCallStatus *out_status);
void uniffi_glsdk_fn_free_nodeeventstream(void * ptr, RustCallStatus *out_status);
RustBuffer uniffi_glsdk_fn_method_nodeeventstream_next(void * ptr, RustCallStatus *out_status);
void * uniffi_glsdk_fn_clone_scheduler(void * ptr, RustCallStatus *out_status);
void uniffi_glsdk_fn_free_scheduler(void * ptr, RustCallStatus *out_status);
void * uniffi_glsdk_fn_constructor_scheduler_new(RustBuffer network, RustCallStatus *out_status);
void * uniffi_glsdk_fn_method_scheduler_recover(void * ptr, void * signer, RustCallStatus *out_status);
void * uniffi_glsdk_fn_method_scheduler_register(void * ptr, void * signer, RustBuffer code, RustCallStatus *out_status);
void * uniffi_glsdk_fn_method_scheduler_with_developer_cert(void * ptr, void * cert, RustCallStatus *out_status);
void * uniffi_glsdk_fn_clone_signer(void * ptr, RustCallStatus *out_status);
void uniffi_glsdk_fn_free_signer(void * ptr, RustCallStatus *out_status);
void * uniffi_glsdk_fn_constructor_signer_new(RustBuffer phrase, RustCallStatus *out_status);
void * uniffi_glsdk_fn_constructor_signer_new_from_seed(RustBuffer seed, RustCallStatus *out_status);
void * uniffi_glsdk_fn_method_signer_authenticate(void * ptr, void * creds, RustCallStatus *out_status);
RustBuffer uniffi_glsdk_fn_method_signer_node_id(void * ptr, RustCallStatus *out_status);
void * uniffi_glsdk_fn_method_signer_start(void * ptr, RustCallStatus *out_status);
void uniffi_glsdk_fn_init_callback_vtable_loglistener(const UniffiVTableCallbackInterfaceLogListener & vtable);
void uniffi_glsdk_fn_init_callback_vtable_nodeeventlistener(const UniffiVTableCallbackInterfaceNodeEventListener & vtable);
RustBuffer uniffi_glsdk_fn_func_parse_input(RustBuffer input, RustCallStatus *out_status);
RustBuffer uniffi_glsdk_fn_func_resolve_input(RustBuffer input, RustCallStatus *out_status);
void uniffi_glsdk_fn_func_set_log_level(RustBuffer level, RustCallStatus *out_status);
void uniffi_glsdk_fn_func_set_logger(RustBuffer level, uint64_t listener, RustCallStatus *out_status);
RustBuffer ffi_glsdk_rustbuffer_alloc(uint64_t size, RustCallStatus *out_status);
RustBuffer ffi_glsdk_rustbuffer_from_bytes(ForeignBytes bytes, RustCallStatus *out_status);
void ffi_glsdk_rustbuffer_free(RustBuffer buf, RustCallStatus *out_status);
RustBuffer ffi_glsdk_rustbuffer_reserve(RustBuffer buf, uint64_t additional, RustCallStatus *out_status);
uint16_t uniffi_glsdk_checksum_func_parse_input();
uint16_t uniffi_glsdk_checksum_func_resolve_input();
uint16_t uniffi_glsdk_checksum_func_set_log_level();
uint16_t uniffi_glsdk_checksum_func_set_logger();
uint16_t uniffi_glsdk_checksum_method_config_with_developer_cert();
uint16_t uniffi_glsdk_checksum_method_config_with_network();
uint16_t uniffi_glsdk_checksum_method_credentials_node_id();
uint16_t uniffi_glsdk_checksum_method_credentials_save();
uint16_t uniffi_glsdk_checksum_method_handle_stop();
uint16_t uniffi_glsdk_checksum_method_node_credentials();
uint16_t uniffi_glsdk_checksum_method_node_disconnect();
uint16_t uniffi_glsdk_checksum_method_node_generate_diagnostic_data();
uint16_t uniffi_glsdk_checksum_method_node_get_info();
uint16_t uniffi_glsdk_checksum_method_node_list_funds();
uint16_t uniffi_glsdk_checksum_method_node_list_invoices();
uint16_t uniffi_glsdk_checksum_method_node_list_payments();
uint16_t uniffi_glsdk_checksum_method_node_list_pays();
uint16_t uniffi_glsdk_checksum_method_node_list_peer_channels();
uint16_t uniffi_glsdk_checksum_method_node_list_peers();
uint16_t uniffi_glsdk_checksum_method_node_lnurl_pay();
uint16_t uniffi_glsdk_checksum_method_node_lnurl_withdraw();
uint16_t uniffi_glsdk_checksum_method_node_node_state();
uint16_t uniffi_glsdk_checksum_method_node_onchain_balance_state();
uint16_t uniffi_glsdk_checksum_method_node_onchain_fee_rates();
uint16_t uniffi_glsdk_checksum_method_node_onchain_receive();
uint16_t uniffi_glsdk_checksum_method_node_onchain_send();
uint16_t uniffi_glsdk_checksum_method_node_prepare_onchain_send();
uint16_t uniffi_glsdk_checksum_method_node_receive();
uint16_t uniffi_glsdk_checksum_method_node_send();
uint16_t uniffi_glsdk_checksum_method_node_stop();
uint16_t uniffi_glsdk_checksum_method_node_stream_node_events();
uint16_t uniffi_glsdk_checksum_method_nodebuilder_connect();
uint16_t uniffi_glsdk_checksum_method_nodebuilder_recover();
uint16_t uniffi_glsdk_checksum_method_nodebuilder_register();
uint16_t uniffi_glsdk_checksum_method_nodebuilder_register_or_recover();
uint16_t uniffi_glsdk_checksum_method_nodebuilder_with_event_listener();
uint16_t uniffi_glsdk_checksum_method_nodeeventstream_next();
uint16_t uniffi_glsdk_checksum_method_scheduler_recover();
uint16_t uniffi_glsdk_checksum_method_scheduler_register();
uint16_t uniffi_glsdk_checksum_method_scheduler_with_developer_cert();
uint16_t uniffi_glsdk_checksum_method_signer_authenticate();
uint16_t uniffi_glsdk_checksum_method_signer_node_id();
uint16_t uniffi_glsdk_checksum_method_signer_start();
uint16_t uniffi_glsdk_checksum_constructor_config_new();
uint16_t uniffi_glsdk_checksum_constructor_credentials_load();
uint16_t uniffi_glsdk_checksum_constructor_developercert_new();
uint16_t uniffi_glsdk_checksum_constructor_nodebuilder_new();
uint16_t uniffi_glsdk_checksum_constructor_scheduler_new();
uint16_t uniffi_glsdk_checksum_constructor_signer_new();
uint16_t uniffi_glsdk_checksum_constructor_signer_new_from_seed();
uint16_t uniffi_glsdk_checksum_method_loglistener_on_log();
uint16_t uniffi_glsdk_checksum_method_nodeeventlistener_on_event();
uint32_t ffi_glsdk_uniffi_contract_version();
#ifdef __cplusplus
}
#endif