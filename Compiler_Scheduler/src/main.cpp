#include <iostream>
#include <string>
#include "utils/Logger.h"
#include "parser/Lexer.h"
#include "parser/Parser.h"
#include "cfg/CFGBuilder.h"
#include "loop/LoopDetector.h"
#include "config/ConfigReader.h"
#include "dependency/DependencyAnalyzer.h"
#include "dfg/DFGBuilder.h"
#include "analysis/CriticalPath.h"
#include "analysis/RegisterPressure.h"
#include "register_partitioning/RegisterPartitioner.h"
#include "scheduling/Scheduler.h"
#include "mapping/PEMapper.h"
#include "output_generator/OutputGenerator.h"
#include "vliw/VLIWGenerator.h"

void printUsage(const char* progName) {
    std::cout << "Uso: " << progName << " <archivo.s>\n";
    std::cout << "\nEjemplo:\n";
    std::cout << "  " << progName << " input/dot_product.s\n";
}

int main(int argc, char* argv[]) {
    // Banner
    std::cout << "╔════════════════════════════════════════════╗\n";
    std::cout << "║   CGRA Compiler - Fases 1, 2, 3 y 4       ║\n";
    std::cout << "║   Parser, CFG, DFG, Scheduling y VLIW      ║\n";
    std::cout << "║   RISC-V RV32IM para ML/AI                 ║\n";
    std::cout << "╚════════════════════════════════════════════╝\n\n";

    if (argc != 2) {
        Logger::error("Número incorrecto de argumentos");
        printUsage(argv[0]);
        return 1;
    }

    std::string inputFile = argv[1];

    Logger::init("output/compiler.log");
    Logger::setLevel(LogLevel::DEBUG);

    Logger::info("=== INICIANDO COMPILACIÓN ===");
    Logger::info("Archivo de entrada: " + inputFile);

    try {
        // ============================================
        // FASE 1: PARSER Y CFG
        // ============================================
        Logger::info("\n========== FASE 1 ==========");

        Logger::info("\n[FASE 1.1] Lexer");
        Lexer lexer(inputFile);
        if (!lexer.readFile()) {
            Logger::error("Fallo en lectura de archivo");
            return 1;
        }

        Logger::info("\n[FASE 1.2] Parser");
        Parser parser(lexer);
        if (!parser.parse()) {
            Logger::error("Fallo en parsing");
            return 1;
        }
        parser.resolveLabels();
        parser.saveToFile("output/phase1_instructions.txt");

        Logger::info("\n[FASE 1.3] CFG Builder");
        CFGBuilder cfgBuilder(parser);
        cfgBuilder.build();
        cfgBuilder.saveCFGToFile("output/phase1_cfg.txt");
        cfgBuilder.saveDotFile("output/phase1_cfg.dot");

        Logger::info("\n[FASE 1.4] Loop Detector");
        LoopDetector loopDetector(cfgBuilder);
        loopDetector.detectLoops();
        loopDetector.saveLoopsToFile("output/phase1_loops.txt");

        // ============================================
        // FASE 2: DEPENDENCIAS Y DFG
        // ============================================
        Logger::info("\n========== FASE 2 ==========");

        Logger::info("\n[FASE 2.1] Configuración");
        ConfigReader config;
        config.loadLatencyConfig("config/latency_config.yaml");
        config.loadHardwareConfig("config/cgra_config.yaml");

        Logger::info("Configuración cargada:");
        Logger::info("  PEs: " + std::to_string(config.getNumPEs()));
        Logger::info("  Registros: " + std::to_string(config.getNumRegisters()));
        Logger::info("  Bancos de memoria: " + std::to_string(config.getMemoryBanks()));

        Logger::info("\n[FASE 2.2] Análisis de Dependencias");
        DependencyAnalyzer depAnalyzer(parser, loopDetector);
        depAnalyzer.analyze();
        depAnalyzer.printDependencies();
        depAnalyzer.saveDependenciesToFile("output/phase2_dependencies.txt");
        depAnalyzer.saveDotFile("output/phase2_dependencies.dot");

        Logger::info("\n[FASE 2.3] Construcción del DFG");
        DFGBuilder dfgBuilder(parser, depAnalyzer, config);
        dfgBuilder.build();

        Logger::info("\n[FASE 2.4] Análisis de Camino Crítico");
        CriticalPath criticalPath(dfgBuilder);
        criticalPath.analyze();  // ← Esto actualiza EST/LST/Slack en los nodos
        criticalPath.printAnalysis();
        criticalPath.saveAnalysisToFile("output/phase2_critical_path.txt");

        // AHORA sí guardar el DFG con valores correctos
        dfgBuilder.saveDFGToFile("output/phase2_dfg.txt");
        dfgBuilder.saveDotFile("output/phase2_dfg.dot");

        Logger::info("\n[FASE 2.5] Análisis de Presión de Registros");
        RegisterPressure regPressure(dfgBuilder, parser, config);
        regPressure.analyze();
        regPressure.printAnalysis();
        regPressure.saveAnalysisToFile("output/phase2_register_pressure.txt");

        // ============================================
        // RESUMEN
        // ============================================
        Logger::info("\n=== RESUMEN FASE 1 ===");
        Logger::info("Instrucciones parseadas: " + std::to_string(parser.getInstructions().size()));
        Logger::info("Labels encontrados: " + std::to_string(parser.getLabels().size()));
        Logger::info("Bloques básicos: " + std::to_string(cfgBuilder.getBlocks().size()));
        Logger::info("Loops detectados: " + std::to_string(loopDetector.getLoops().size()));

        int cgra_candidates = 0;
        for (const auto& loop : loopDetector.getLoops()) {
            if (loop->isCGRACandidate()) cgra_candidates++;
        }
        Logger::info("Loops candidatos para CGRA: " + std::to_string(cgra_candidates));

        Logger::info("\n=== RESUMEN FASE 2 ===");
        Logger::info("Dependencias detectadas: " + std::to_string(depAnalyzer.getDependencies().size()));
        Logger::info("Nodos en DFG: " + std::to_string(dfgBuilder.getNodes().size()));
        Logger::info("Camino crítico: " + std::to_string(criticalPath.getCriticalPathLength()) + " ciclos");
        Logger::info("Paralelismo disponible (ILP): " + std::to_string(criticalPath.getAverageParallelism()));
        Logger::info("Presión máxima de registros: " + std::to_string(regPressure.getMaxPressure()) +
        " / " + std::to_string(config.getNumRegisters()));

        if (regPressure.getNeedsSpilling()) {
            Logger::warning("ADVERTENCIA: Se requiere spilling de registros");
        }

        // ============================================
        // FASE 3: SCHEDULING Y MAPEO
        // ============================================
        Logger::info("\n========== FASE 3 ==========");

        Logger::info("\n[FASE 3.1] Particionamiento de Registros");
        RegisterPartitioner partitioner(config);
        partitioner.createPartitions();
        partitioner.printPartitioning();
        partitioner.saveToFile("output/phase3_register_partitioning.txt");

        Logger::info("\n[FASE 3.2] List Scheduling");
        Scheduler scheduler(parser, dfgBuilder, config, partitioner);
        scheduler.schedule();
        scheduler.printSchedule();
        scheduler.saveToFile("output/phase3_schedule.txt");

        Logger::info("\n[FASE 3.3] Análisis de Mapeo a PEs");
        PEMapper mapper(scheduler, config);
        mapper.analyzeMapping();
        mapper.printMapping();
        mapper.saveToFile("output/phase3_mapping.txt");

        Logger::info("\n[FASE 3.4] Generación de Archivos de Salida");
        OutputGenerator generator(scheduler, mapper, parser, config);
        generator.generateAll("output");

        // ============================================
        // FASE 4: GENERACIÓN VLIW
        // ============================================
        Logger::info("\n========== FASE 4 ==========");
        
        // Extraer nombre base del archivo de entrada
        std::string baseName = inputFile;
        size_t lastSlash = baseName.find_last_of("/\\");
        if (lastSlash != std::string::npos) {
            baseName = baseName.substr(lastSlash + 1);
        }
        size_t lastDot = baseName.find_last_of('.');
        if (lastDot != std::string::npos) {
            baseName = baseName.substr(0, lastDot);
        }
        
        Logger::info("\n[FASE 4.1] Generación de Instrucciones VLIW de 128 bits");
        VLIWGenerator vliwGen(scheduler, parser, config);
        vliwGen.generate();
        
        Logger::info("\n[FASE 4.2] Guardando Archivos VLIW");
        vliwGen.saveAllFormats("output", baseName);
        
        Logger::info("\n[FASE 4.3] Estadísticas VLIW");
        vliwGen.printStatistics();

        // ============================================
        // RESUMEN FINAL
        // ============================================
        Logger::info("\n=== RESUMEN FASE 3 ===");
        Logger::info("Instrucciones calendarizadas: " + std::to_string(scheduler.getSchedule().size()));
        Logger::info("Makespan: " + std::to_string(scheduler.getMakespan()) + " ciclos");
        Logger::info("IPC: " + std::to_string(mapper.getIPC()));
        Logger::info("Utilización de PEs: " + std::to_string(mapper.getOverallUtilization()) + "%");
        
        Logger::info("\n=== RESUMEN FASE 4 ===");
        Logger::info("Palabras VLIW generadas: " + std::to_string(vliwGen.getVLIWInstructions().size()));
        Logger::info("Formato: 128 bits (4 PEs × 32 bits)");
        Logger::info("PE0: bits [31:0]   (menos significativo)");
        Logger::info("PE1: bits [63:32]");
        Logger::info("PE2: bits [95:64]");
        Logger::info("PE3: bits [127:96] (más significativo)");

        Logger::info("\nArchivos generados en output/:");
        Logger::info("  Fase 1:");
        Logger::info("    - phase1_instructions.txt");
        Logger::info("    - phase1_cfg.txt / .dot");
        Logger::info("    - phase1_loops.txt");
        Logger::info("  Fase 2:");
        Logger::info("    - phase2_dependencies.txt / .dot");
        Logger::info("    - phase2_dfg.txt / .dot");
        Logger::info("    - phase2_critical_path.txt");
        Logger::info("    - phase2_register_pressure.txt");
        Logger::info("  Fase 3:");
        Logger::info("    - phase3_register_partitioning.txt");
        Logger::info("    - phase3_schedule.txt");
        Logger::info("    - phase3_mapping.txt");
        Logger::info("    - phase3_metrics.txt");
        Logger::info("    - phase3_hardware.txt");
        Logger::info("    - phase3_arbiter_stats.txt");
        Logger::info("    - phase3_visualization.txt");
        Logger::info("    - phase3_combined.txt");
        Logger::info("  Fase 4:");
        Logger::info("    - " + baseName + ".bin (binario puro)");
        Logger::info("    - " + baseName + "_concatenated.hex (128-bit VLIW concatenado)");
        Logger::info("    - " + baseName + "_separated.hex (32-bit por línea)");
        Logger::info("    - " + baseName + ".mem (Verilog $readmemh)");
        Logger::info("    - " + baseName + ".s (assembly anotado)");
        Logger::info("    - " + baseName + ".elf (ejecutable ELF)");
        Logger::info("    - " + baseName + "_detailed.txt (detallado con comentarios)");
        Logger::info("    - compiler.log");

        Logger::info("\n=== TODAS LAS FASES (1-4) COMPLETADAS EXITOSAMENTE ===");

    } catch (const std::exception& e) {
        Logger::error("Excepción capturada: " + std::string(e.what()));
        return 1;
    }

    Logger::close();
    return 0;
}
