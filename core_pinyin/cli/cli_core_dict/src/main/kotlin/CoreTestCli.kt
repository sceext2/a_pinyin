package org.sceext.a_pinyin.core_dict

import java.io.FileOutputStream
import java.sql.Connection
import java.sql.DriverManager

import com.beust.klaxon.JsonObject

import com.esotericsoftware.kryo.Kryo
import com.esotericsoftware.kryo.io.Output
import com.esotericsoftware.kryo.io.Input

import org.sceext.a_pinyin.cli_lib.parse_json
import org.sceext.a_pinyin.cli_lib.read_text_file


fun _print_help() {
    val text = """
    | Avaliable commands:
    |     .exit    Exit command loop
    |     .help    Show this help text
    """.trimMargin()
    println(text)
}


fun _one_command(core: ACoreDict, command: String) {
    when(command) {
        // .exit
        ".help" -> _print_help()
        //".config" -> _show_config()
        else -> {
            println("ERROR: unknow command. Please try `.help`")
        }
    }
}

fun _one_pinyin(core: ACoreDict, pinyin: String) {
    try {
        // cut pinyin first
        val raw = pinyin.trim()
        // TODO support more spaces between pinyin ?
        val pinyin_list = raw.split(" ")

        val result = core.get_words(pinyin_list)
        // print all result
        var i = 1
        for (r in result) {
            println(" ${i}\t${r.text}\t ${r.count}")
            i += 1
        }
    } catch (e: Exception) {
        println("ERROR: unknow core Exception, ${e}")
        e.printStackTrace()
    }
}


const val PROMPT: String = "core_dict> "

fun _main_loop(core: ACoreDict) {
    while (true) {
        print(PROMPT)
        val one = readLine()
        if (one == null) {
            break  // just exit command loop
        }
        // empty input
        if (one.trim() == "") {
            continue
        }
        // check for command
        if (one.startsWith(".")) {
            if (one == ".exit") {
                break
            }
            _one_command(core, one)
        } else {  // normal pinyin
            _one_pinyin(core, one)
        }
    }
}


// init core
fun _load_data_json(filename: String): ACoreDictData {
    println("DEBUG: start load json data ${filename}")
    val text = read_text_file(filename)

    println("DEBUG: parse json")
    val data = parse_json(text)

    println("DEBUG: core_data.load_json()")
    val core_data = ACoreDictData()
    core_data.load_json(data)

    return core_data
}

fun _export_data_kryo(filename: String, data: ACoreDictData) {
    println("DEBUG: export kryo data to ${filename}")

    val kryo = Kryo()
    val o = Output(FileOutputStream(filename))
    kryo.writeObject(o, data)
    o.close()
}

fun _load_data_kryo(data: ByteArray): ACoreDictData {
    println("DEBUG: load kryo blob")

    val kryo = Kryo()
    val i = Input(data.inputStream())
    val o = kryo.readObject(i, ACoreDictData::class.java)
    i.close()

    return o
}

fun main(args: Array<String>) {
    val data_file = args[0]
    // check export
    if (args.size > 1) {
        val export_file = args[1]
        val core_data = _load_data_json(data_file)

        _export_data_kryo(export_file, core_data)
        return
    }

    // open sqlite3 database
    println("DEBUG: connect to sqlite3 database ${data_file}")
    val conn = DriverManager.getConnection("jdbc:sqlite:${data_file}")

    // load core kryo data
    val p = conn.prepareStatement("SELECT kryo FROM a_pinyin_core_data WHERE name = ?")
    p.setString(1, "core_dict")
    val r = p.executeQuery()
    r.next()
    val blob = r.getBytes(1)
    val core_data = _load_data_kryo(blob)


    // create core and load data
    val core = ACoreDict()

    println("DEBUG: core.load_data()")
    core.load_data(core_data)
    // core use database
    core.set_connection(conn)

    // core init done, enter CLI
    _main_loop(core)

    // close database connection
    conn.close()
}
