# frozen_string_literal: true

module ANCService
    class PatientVisitLabel
      attr_accessor :patient, :date
  
      def initialize(patient, date)
        @patient = patient
        @date = date
      end

      def print
        self.print1 + self.print2
      end
  
      def print1
        visit = ANCService::PatientVisit.new patient, date
        return unless visit

        @current_range = visit.active_range(@date.to_date)

        encounters = {}

        @patient.encounters.where(["encounter_datetime >= ? AND encounter_datetime <= ?",
          @current_range[0]["START"], @current_range[0]["END"]]).collect{|e|
            encounters[e.encounter_datetime.strftime("%d/%b/%Y")] = {"USER" => User.find(e.creator).username }
        }

        @patient.encounters.where(["encounter_datetime >= ? AND encounter_datetime <= ?",
          @current_range[0]["START"], @current_range[0]["END"]]).collect{|e|
          encounters[e.encounter_datetime.strftime("%d/%b/%Y")][e.type.name.upcase] = ({} rescue "") if !e.type.nil?
        }

        @patient.encounters.where(["encounter_datetime >= ? AND encounter_datetime <= ?",
          @current_range[0]["START"], @current_range[0]["END"]]).collect{|e|
            if !e.type.nil?
              e.observations.each{|o|
                if o.to_a[0]
                  if o.to_a[0].upcase == "DIAGNOSIS" && encounters[e.encounter_datetime.strftime("%d/%b/%Y")][e.type.name.upcase][o.to_a[0].upcase]
                    encounters[e.encounter_datetime.strftime("%d/%b/%Y")][e.type.name.upcase][o.to_a[0].upcase] += "; " + o.to_a[1]
                  else
                    encounters[e.encounter_datetime.strftime("%d/%b/%Y")][e.type.name.upcase][o.to_a[0].upcase] = o.to_a[1]
                    if o.to_a[0].upcase == "PLANNED DELIVERY PLACE"
                      @current_range[0]["PLANNED DELIVERY PLACE"] = o.to_a[1]
                    elsif o.to_a[0].upcase == "MOSQUITO NET"
                      @current_range[0]["MOSQUITO NET"] = o.to_a[1]
                    end
                  end
                end
              } rescue nil
            end
          }

          @drugs = {};
          @other_drugs = {};
          main_drugs = ["TTV", "SP", "Fefol", "Albendazole"]

          @patient.encounters.where(["(encounter_type = ? OR encounter_type = ?) AND encounter_datetime >= ? AND encounter_datetime <= ?",
              EncounterType.find_by_name("TREATMENT").id, EncounterType.find_by_name("DISPENSING").id,
              @current_range[0]["START"], @current_range[0]["END"]]).order("encounter_datetime DESC").each{|e|
            @drugs[e.encounter_datetime.strftime("%d/%b/%Y")] = {} if !@drugs[e.encounter_datetime.strftime("%d/%b/%Y")];
            @other_drugs[e.encounter_datetime.strftime("%d/%b/%Y")] = {} if !@other_drugs[e.encounter_datetime.strftime("%d/%b/%Y")];
            e.orders.each{|o|

              drug_name = o.drug_order.drug.name.match(/syrup|\d+\.*\d+mg|\d+\.*\d+\smg|\d+\.*\d+ml|\d+\.*\d+\sml/i) ?
                (o.drug_order.drug.name[0, o.drug_order.drug.name.index(" ")].to_s + " " +
                  o.drug_order.drug.name.match(/syrup|\d+\.*\d+mg|\d+\.*\d+\smg|\d+\.*\d+ml|\d+\.*\d+\sml/i)[0]) :
                (o.drug_order.drug.name[0, o.drug_order.drug.name.index(" ")]) rescue o.drug_order.drug.name

              if ((main_drugs.include?(o.drug_order.drug.name[0, o.drug_order.drug.name.index(" ")])) rescue false)

                @drugs[e.encounter_datetime.strftime("%d/%b/%Y")][o.drug_order.drug.name[0,
                    o.drug_order.drug.name.index(" ")]] = o.drug_order.amount_needed
              else

                @other_drugs[e.encounter_datetime.strftime("%d/%b/%Y")][drug_name] = o.drug_order.amount_needed
              end
            }
          }

          label = ZebraPrinter::StandardLabel.new

          label.draw_line(20,25,800,2,0)
          label.draw_line(20,25,2,280,0)
          label.draw_line(20,305,800,2,0)
          label.draw_line(805,25,2,280,0)
          label.draw_text("Visit Summary",28,33,0,1,1,2,false)
          label.draw_text("Last Menstrual Period: #{@current_range[0]["START"].to_date.strftime("%d/%b/%Y") rescue ""}",28,76,0,2,1,1,false)
          label.draw_text("Expected Date of Delivery: #{(@current_range[0]["END"].to_date - 5.week).strftime("%d/%b/%Y") rescue ""}",28,99,0,2,1,1,false)
          label.draw_line(28,60,132,1,0)
          label.draw_line(20,130,800,2,0)
          label.draw_line(20,190,800,2,0)
          label.draw_text("Gest.",29,140,0,2,1,1,false)
          label.draw_text("Fundal",99,140,0,2,1,1,false)
          label.draw_text("Pos./",178,140,0,2,1,1,false)
          label.draw_text("Fetal",259,140,0,2,1,1,false)
          label.draw_text("Weight",339,140,0,2,1,1,false)
          label.draw_text("(kg)",339,158,0,2,1,1,false)
          label.draw_text("BP",435,140,0,2,1,1,false)
          label.draw_text("Urine",499,138,0,2,1,1,false)
          label.draw_text("Prote-",499,156,0,2,1,1,false)
          label.draw_text("in",505,174,0,2,1,1,false)
          label.draw_text("SP",595,140,0,2,1,1,false)
          label.draw_text("(tabs)",575,158,0,2,1,1,false)
          label.draw_text("FeFo",664,140,0,2,1,1,false)
          label.draw_text("(tabs)",655,158,0,2,1,1,false)
          label.draw_text("Albe.",740,140,0,2,1,1,false)
          label.draw_text("(tabs)",740,156,0,2,1,1,false)
          label.draw_text("Age",35,158,0,2,1,1,false)
          label.draw_text("Height",99,158,0,2,1,1,false)
          label.draw_text("Pres.",178,158,0,2,1,1,false)
          label.draw_text("Heart",259,158,0,2,1,1,false)
          label.draw_line(90,130,2,175,0)
          label.draw_line(170,130,2,175,0)
          label.draw_line(250,130,2,175,0)
          label.draw_line(330,130,2,175,0)
          label.draw_line(410,130,2,175,0)
          label.draw_line(490,130,2,175,0)
          label.draw_line(570,130,2,175,0)
          label.draw_line(650,130,2,175,0)
          label.draw_line(730,130,2,175,0)

          @i = 0

          out = []

          encounters.each{|v,k|
            out << [k["ANC VISIT TYPE"]["REASON FOR VISIT"].squish.to_i, v] rescue []
          }
          out = out.sort.compact

          # raise out.to_yaml

          out.each do |key, element|

            encounter = encounters[element]

            @i = @i + 1

            if element == target_date.to_date.strftime("%d/%b/%Y")
              visit = encounters[element]["ANC VISIT TYPE"]["REASON FOR VISIT"].to_i

              label.draw_text("Visit No: #{visit}",250,33,0,1,1,2,false)
              label.draw_text("Visit Date: #{element}",450,33,0,1,1,2,false)

              gest = (((element.to_date - @current_range[0]["START"].to_date).to_i / 7) <= 0 ? "?" :
                  (((element.to_date - @current_range[0]["START"].to_date).to_i / 7) - 1).to_s + "wks") rescue ""

              label.draw_text(gest,29,200,0,2,1,1,false)

              fund = (encounters[element]["OBSERVATIONS"]["FUNDUS"].to_i <= 0 ? "?" :
                  encounters[element]["OBSERVATIONS"]["FUNDUS"].to_i.to_s + "(cm)") rescue ""

              label.draw_text(fund,99,200,0,2,1,1,false)

              posi = encounters[element]["OBSERVATIONS"]["POSITION"] rescue ""
              pres = encounters[element]["OBSERVATIONS"]["PRESENTATION"] rescue ""

              posipres = paragraphate(posi.to_s + pres.to_s,5, 5)

              (0..(posipres.length)).each{|u|
                label.draw_text(posipres[u].to_s,178,(200 + (13 * u)),0,2,1,1,false)
              }

              fet = (encounters[element]["OBSERVATIONS"]["FETAL HEART BEAT"].humanize == "Unknown" ? "?" :
                  encounters[element]["OBSERVATIONS"]["FETAL HEART BEAT"].humanize).gsub(/Fetal\smovement\sfelt\s\(fmf\)/i,"FMF") rescue ""

              fet = paragraphate(fet, 5, 5)

              (0..(fet.length)).each{|f|
                label.draw_text(fet[f].to_s,259,(200 + (13 * f)),0,2,1,1,false)
              }

              wei = (encounters[element]["VITALS"]["WEIGHT (KG)"].to_i <= 0 ? "?" :
                  ((encounters[element]["VITALS"]["WEIGHT (KG)"].to_s.match(/\.[1-9]/) ?
                      encounters[element]["VITALS"]["WEIGHT (KG)"] :
                      encounters[element]["VITALS"]["WEIGHT (KG)"].to_i))) rescue ""

              label.draw_text(wei,339,200,0,2,1,1,false)

              sbp = (encounters[element]["VITALS"]["SYSTOLIC BLOOD PRESSURE"].to_i <= 0 ? "?" :
                  encounters[element]["VITALS"]["SYSTOLIC BLOOD PRESSURE"].to_i) rescue "?"

              dbp = (encounters[element]["VITALS"]["DIASTOLIC BLOOD PRESSURE"].to_i <= 0 ? "?" :
                  encounters[element]["VITALS"]["DIASTOLIC BLOOD PRESSURE"].to_i) rescue "?"

              bp = paragraphate(sbp.to_s + "/" + dbp.to_s, 4, 3)

              (0..(bp.length)).each{|u|
                label.draw_text(bp[u].to_s,420,(200 + (18 * u)),0,2,1,1,false)
              }

              uri = encounters[element]["LAB RESULTS"]["URINE PROTEIN"] rescue ""

              uri = paragraphate(uri, 5, 5)

              (0..(uri.length)).each{|u|
                label.draw_text(uri[u].to_s,498,(200 + (18 * u)),0,2,1,1,false)
              }

              sp = (@drugs[element]["SP"].to_i > 0 ? @drugs[element]["SP"].to_i : "") rescue ""

              label.draw_text(sp,595,200,0,2,1,1,false)

              @ferrous_fefol =  @other_drugs.keys.collect{|date|
                @other_drugs[date].keys.collect{|key|
                  @other_drugs[date][key] if ((@other_drugs[date][key].to_i > 0 and key.downcase.strip == "ferrous") rescue false)
                }
              }.compact.first.to_s rescue ""

              fefo = (@drugs[element]["Fefol"].to_i > 0 ? @drugs[element]["Fefol"].to_i : "") rescue ""

              fefo = (fefo.to_i + @ferrous_fefol.to_i) rescue fefo
              fefo = "" if (fefo.to_i == 0 rescue false)

              label.draw_text(fefo.to_s,664,200,0,2,1,1,false)

              albe = (@drugs[element]["Albendazole"].to_i > 0 ? @drugs[element]["Albendazole"].to_i : "") rescue ""

              label.draw_text(albe.to_s,740,200,0,2,1,1,false)
            end

          end

          @encounters = encounters

          label.print(1)
        end

        def print2
          visit = ANCService::PatientVisit.new patient, date
          return unless visit
    
          @current_range = visit.active_range(@date.to_date)
    
          # raise @current_range.to_yaml
    
          encounters = {}
    
          @patient.encounters.where(["encounter_datetime >= ? AND encounter_datetime <= ?",
              @current_range[0]["START"], @current_range[0]["END"]]).collect{|e|
            encounters[e.encounter_datetime.strftime("%d/%b/%Y")] = {"USER" => User.find(e.creator).username}
          }
    
          @patient.encounters.where(["encounter_datetime >= ? AND encounter_datetime <= ?",
              @current_range[0]["START"], @current_range[0]["END"]]).collect{|e|
            encounters[e.encounter_datetime.strftime("%d/%b/%Y")][e.type.name.upcase] = ({} rescue "") if !e.type.nil?
          }
    
          @patient.encounters.where(["encounter_datetime >= ? AND encounter_datetime <= ?",
              @current_range[0]["START"], @current_range[0]["END"]]).collect{|e|
            e.observations.each{|o|
              if o.to_a[0]
                if o.to_a[0].upcase == "DIAGNOSIS" && encounters[e.encounter_datetime.strftime("%d/%b/%Y")][e.type.name.upcase][o.to_a[0].upcase]
                  encounters[e.encounter_datetime.strftime("%d/%b/%Y")][e.type.name.upcase][o.to_a[0].upcase] += "; " + o.to_a[1]
                else
                  encounters[e.encounter_datetime.strftime("%d/%b/%Y")][e.type.name.upcase][o.to_a[0].upcase] = (o.to_a[1] rescue "") if !e.type.nil?
                  if o.to_a[0].upcase == "PLANNED DELIVERY PLACE"
                    @current_range[0]["PLANNED DELIVERY PLACE"] = o.to_a[1]
                  elsif o.to_a[0].upcase == "MOSQUITO NET"
                    @current_range[0]["MOSQUITO NET"] = o.to_a[1]
                  end
                end
              end
            } rescue nil
          }
    
          @drugs = {};
          @other_drugs = {};
          main_drugs = ["TTV", "SP", "Fefol", "Albendazole"]
    
          @patient.encounters.where(["(encounter_type = ? OR encounter_type = ?) AND encounter_datetime >= ? AND encounter_datetime <= ?",
              EncounterType.find_by_name("TREATMENT").id, EncounterType.find_by_name("DISPENSING").id,
              @current_range[0]["START"], @current_range[0]["END"]]).order("encounter_datetime DESC").each{|e|
            @drugs[e.encounter_datetime.strftime("%d/%b/%Y")] = {} if !@drugs[e.encounter_datetime.strftime("%d/%b/%Y")];
            @other_drugs[e.encounter_datetime.strftime("%d/%b/%Y")] = {} if !@other_drugs[e.encounter_datetime.strftime("%d/%b/%Y")];
            e.orders.each{|o|
    
              drug_name = o.drug_order.drug.name.match(/syrup|\d+\.*\d+mg|\d+\.*\d+\smg|\d+\.*\d+ml|\d+\.*\d+\sml/i) ?
                (o.drug_order.drug.name[0, o.drug_order.drug.name.index(" ")] + " " +
                  o.drug_order.drug.name.match(/syrup|\d+\.*\d+mg|\d+\.*\d+\smg|\d+\.*\d+ml|\d+\.*\d+\sml/i)[0]) :
                (o.drug_order.drug.name[0, o.drug_order.drug.name.index(" ")]) rescue o.drug_order.drug.name
    
              if ((main_drugs.include?(o.drug_order.drug.name[0, o.drug_order.drug.name.index(" ")])) rescue false)
    
                @drugs[e.encounter_datetime.strftime("%d/%b/%Y")][o.drug_order.drug.name[0,
                    o.drug_order.drug.name.index(" ")]] = o.drug_order.amount_needed
              else
    
                @other_drugs[e.encounter_datetime.strftime("%d/%b/%Y")][drug_name] = o.drug_order.amount_needed
              end
            }
          }
    
          label = ZebraPrinter::StandardLabel.new
    
          label.draw_line(20,25,800,2,0)
          label.draw_line(20,25,2,280,0)
          label.draw_line(20,305,800,2,0)
          label.draw_line(805,25,2,280,0)
    
          label.draw_line(20,130,800,2,0)
          label.draw_line(20,190,800,2,0)
    
          label.draw_line(160,130,2,175,0)
          label.draw_line(364,130,2,175,0)
          label.draw_line(594,130,2,175,0)
          label.draw_line(706,130,2,175,0)
          label.draw_text("Planned Delivery Place: #{@current_range[0]["PLANNED DELIVERY PLACE"] rescue ""}",28,66,0,2,1,1,false)
          label.draw_text("Bed Net Given: #{@current_range[0]["MOSQUITO NET"] rescue ""}",28,99,0,2,1,1,false)
          label.draw_text("",28,138,0,2,1,1,false)
          label.draw_text("TTV",75,156,0,2,1,1,false)
    
          label.draw_text("Diagnosis",170,140,0,2,1,1,false)
          label.draw_text("Medication/Outcome",370,140,0,2,1,1,false)
          label.draw_text("Next Vis.",600,140,0,2,1,1,false)
          label.draw_text("Date",622,158,0,2,1,1,false)
          label.draw_text("Provider",710,140,0,2,1,1,false)
    
          @i = 0
    
          out = []
    
          encounters.each{|v,k|
            out << [k["ANC VISIT TYPE"]["REASON FOR VISIT"].squish.to_i, v] rescue []
          }
          out = out.sort.compact
    
          # raise out.to_yaml
    
          out.each do |key, element|
    
            encounter = encounters[element]
            @i = @i + 1
    
            if element == target_date.to_date.strftime("%d/%b/%Y")
    
              ttv = (@drugs[element]["TTV"] > 0 ? 1 : "") rescue ""
    
              label.draw_text(ttv.to_s,28,200,0,2,1,1,false)
    
              sign = encounters[element]["OBSERVATIONS"]["DIAGNOSIS"].humanize rescue ""
    
              sign = paragraphate(sign.to_s, 13, 5)
    
              (0..(sign.length)).each{|m|
                label.draw_text(sign[m].to_s,175,(200 + (25 * m)),0,2,1,1,false)
              }
    
              med = encounters[element]["UPDATE OUTCOME"]["OUTCOME"].humanize + "; " rescue ""
              oth = (@other_drugs[element].collect{|d, v|
                  "#{d}: #{ (v.to_s.match(/\.[1-9]/) ? v : v.to_i) }"
                }.join("; ")) if @other_drugs[element].length > 0 rescue ""
    
              med = paragraphate(med.to_s + oth.to_s, 17, 5)
    
              (0..(med.length)).each{|m|
                label.draw_text(med[m].to_s,370,(200 + (18 * m)),0,2,1,1,false)
              }
    
              nex = encounters[element]["APPOINTMENT"]["APPOINTMENT DATE"] rescue []
    
              if nex != []
                date = nex.to_date
                nex = []
                nex << date.strftime("%d/")
                nex << date.strftime("%b/")
                nex << date.strftime("%Y")
              end
    
              (0..(nex.length)).each{|m|
                label.draw_text(nex[m].to_s,610,(200 + (18 * m)),0,2,1,1,false)
              }
    
              use = (encounters[element]["USER"].split(" ") rescue []).collect{|n| n[0,1].upcase + "."}.join("")  rescue ""
    
              # use = paragraphate(use.to_s, 5, 5)
    
              # (0..(use.length)).each{|m|
              #   label.draw_text(use[m],710,(200 + (18 * m)),0,2,1,1,false)
              # }
    
              label.draw_text(use.to_s,710,200,0,2,1,1,false)
    
            end
          end
    
          label.print(1)
      end
      
      end

    end