#include "config.h"
#include "util.h"

#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QUuid>
#include <QTextStream>

#ifdef ENABLE_SENTRY

#include <google_breakpad/processor/basic_source_line_resolver.h>
#include <google_breakpad/processor/call_stack.h>
#include <google_breakpad/processor/minidump.h>
#include <google_breakpad/processor/minidump_processor.h>
#include <google_breakpad/processor/process_state.h>
#include <google_breakpad/processor/stack_frame.h>
#include <processor/simple_symbol_supplier.h>
#include <processor/stackwalk_common.h>

namespace {

using google_breakpad::BasicSourceLineResolver;
using google_breakpad::Minidump;
using google_breakpad::MinidumpMemoryList;
using google_breakpad::MinidumpProcessor;
using google_breakpad::ProcessState;

QString ToHex(uint64_t address) {
    return QString("0x%1").arg(address, 0, 16, QChar('0'));
}

}  // namespace

bool SentryPayloadFromMinidump(const QString& path, QByteArray& envelope)
{
    Minidump dump(path.toStdString());
    if (!dump.Read()) {
        return false;
    }

    BasicSourceLineResolver resolver;
    MinidumpProcessor processor(nullptr, &resolver);
    ProcessState state;
    if (processor.Process(&dump, &state) != google_breakpad::PROCESS_OK) {
        return false;
    }

    QJsonObject contexts;
    contexts.insert("device", QJsonObject{
        { "type", "device" },
        { "arch", QSysInfo::currentCpuArchitecture() },
        { "model", GetHardwareModel() }
    });
    contexts.insert("os", QJsonObject{
        { "type", "os" },
        { "name", QSysInfo::prettyProductName() },
        { "version", QSysInfo::productVersion() },
        { "kernel_version", QSysInfo::kernelVersion() }
    });
    contexts.insert("app", QJsonObject{
        { "type", "app" },
        { "app_name", "green" },
        { "app_version", GREEN_VERSION }
    });

    QJsonObject exception;
    {
        QJsonArray frames;
        for (const auto stack_frame : *(state.threads()->at(state.requesting_thread())->frames())) {
            uint64_t instruction_address = stack_frame->ReturnAddress();
            frames.prepend(QJsonObject{
                { "instruction_addr", ToHex(instruction_address) },
                { "package", QString::fromStdString(stack_frame->module->code_file()) },
            });
        }

        exception.insert("values", QJsonArray{
            QJsonObject{
                { "type", QString::fromStdString(state.crash_reason()) },
                { "value", QString::fromStdString(state.crash_reason()) },
                { "stacktrace", QJsonObject{
                    { "frames", frames }
                }}
            }
        });
    }

    // TODO: include threads and stacktraces
    // QJsonObject threads;
    // {
    //     QJsonArray values;
    //     for (const auto call_stack : *state.threads()) {
    //         QJsonArray frames;
    //         for (const auto stack_frame : *call_stack->frames()) {
    //             if (stack_frame->module) {
    //                 uint64_t instruction_address = stack_frame->ReturnAddress();
    //                 frames.append(QJsonObject{
    //                     { "instruction_addr", ToHex(instruction_address) },
    //                     { "package", QString::fromStdString(stack_frame->module->code_file()) }
    //                 });
    //             }
    //         }
    //         values.append(QJsonObject{
    //             { "id", (qint64) call_stack->tid() },
    //             { "stacktrace", QJsonObject{
    //                 { "frames", frames }
    //             }}
    //         });
    //     }
    //     threads.insert("values", values);
    // }

    QJsonObject debug_meta;
    {
        QJsonArray images;
        for (int i = 0; i < state.modules()->module_count(); i++) {
            auto module = state.modules()->GetModuleAtIndex(i);
            const auto id = QString::fromStdString(module->debug_identifier()).toLower();
            const auto code_id = id.mid(0, 32);
            const auto debug_id = id.mid(0, 8) + "-" + id.mid(8, 4) + "-" + id.mid(12, 4) + "-" + id.mid(16, 4) + "-" + id.mid(20, 12);
            images.append(QJsonObject{
#if defined(Q_OS_APPLE)
                { "type", "macho" },
#elif defined(Q_OS_LINUX)
                { "type", "elf" },
#elif defined(Q_OS_WINDOWS)
                { "type", "pe" },
#endif
                { "image_addr", ToHex(module->base_address()) },
                { "image_size", (qint64) module->size() },
                { "debug_id", debug_id },
                { "debug_file", QString::fromStdString(module->debug_file()) },
                { "code_id", code_id },
                { "code_file", QString::fromStdString(module->code_file()) },
            });
        }
        debug_meta.insert("images", images);
    }

    QJsonObject header{{"event_id", QUuid::createUuid().toString(QUuid::Id128)}};
    QJsonObject item{{"type", "event"}};
    QJsonObject body;
    body.insert("platform", "native");
    body.insert("level", "fatal");
    body.insert("environment", "production");
    body.insert("contexts", contexts);
    body.insert("exception", exception);
    body.insert("debug_meta", debug_meta);
    // body.insert("threads", threads);

    QTextStream(&envelope)
        << qPrintable(QJsonDocument(header).toJson(QJsonDocument::Compact)) << "\n"
        << qPrintable(QJsonDocument(item).toJson(QJsonDocument::Compact)) << "\n"
        << qPrintable(QJsonDocument(body).toJson(QJsonDocument::Compact)) << "\n";

    return true;
}

#endif
