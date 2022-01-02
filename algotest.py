import copy
import math
import random
from statistics import variance

class Goal:
    def __init__(self, name, days_per_week, hours_per_day, category):
        self.name = name
        self.days_per_week = days_per_week
        self.hours_per_day = hours_per_day
        self.category = category


class Task:
    def __init__(self, name, duration, weekday=None, start=None, end=None, category=None):
        self.name = name
        self.duration = duration
        self.weekday = weekday
        self.start = start
        self.end = end
        self.category = category

def pending_tasks(goals):
    result = []

    for goal in goals:
        for _ in range(goal.days_per_week):
            result.append(Task(goal.name, goal.hours_per_day, category=goal.category))

    return result

def fill_week_table(fixed, min_hour, max_hour):
    n = 7 * 24
    table = [ False for _ in range(n) ]

    for t in fixed:
        start = t.weekday * 24 + t.start
        end = start + t.duration

        for i in range(start, end):
            table[i] = True

        # riempio un'ora in più per lasciare un'ora di gioco libera fra due task successivi
        table[end] = True
    
    for i in range(7):
        for j in range(0, min_hour):
            table[i * 24 + j] = True
        for j in range(max_hour, 24):
            table[i * 24 + j] = True
    
    return table


def is_free(table, index, duration):
    for i in range(index, index + duration):
        if table[i]:
            return False
    
    return True


def cost(fixed, pending, log=False):
    busy_hours = [ 0 for _ in range(7) ]
    education_hours = [ 0 for _ in range(7) ]
    sport_hours = [ 0 for _ in range(7) ]
    other_hours = [ 0 for _ in range(7) ]

    goal_days = {}
    goal_tasks_count = {}

    for t in fixed:
        busy_hours[t.weekday] = busy_hours[t.weekday] + t.duration
    
    for t in pending:
        if t.name not in goal_days:
            goal_days[t.name] = set()
            goal_tasks_count[t.name] = 0

        goal_days[t.name].add(t.weekday)
        goal_tasks_count[t.name] = goal_tasks_count[t.name] + 1

        busy_hours[t.weekday] = busy_hours[t.weekday] + t.duration

        if t.category == 'EDUCAZIONE':
            education_hours[t.weekday] = education_hours[t.weekday] + t.duration
        elif t.category == 'SPORT':
            sport_hours[t.weekday] = sport_hours[t.weekday] + t.duration
        else:
            other_hours[t.weekday] = other_hours[t.weekday] + t.duration

    for goal in goal_days:
        if len(goal_days[goal]) != goal_tasks_count[goal]:
            return math.inf

    weight = variance(busy_hours) * variance(education_hours) * variance(sport_hours) * variance(other_hours)
    
    if log:
        print(f'busy = {busy_hours}, education = {education_hours}, sport = {sport_hours}, other = {other_hours}, weight = {weight}')

    return weight


def sort_key(task):
    return task.weekday * 24 + task.start


def schedule(fixed, goals, tries=100000):
    pending = pending_tasks(goals)
    day_average = len(pending) / 7
    week_table = fill_week_table(fixed, 8, 23)
    best = []
    best_cost = math.inf
    i = 0

    fixed.sort(key=sort_key)

    while i < tries:
        assigned = [ 0 for _ in range(7) ]
        index = 0
        count = 0

        for t in pending:
            t.weekday = None
            t.start = None
            t.end = None
        
        random.shuffle(pending)

        for t in pending:
            day = math.floor(index / 24)

            if assigned[day] > day_average:
                day = day + 1
                index = day * 24

            while index < len(week_table):
                if is_free(week_table, index, t.duration):
                    t.weekday = day
                    t.start = index % 24
                    t.end = t.start + t.duration
                    # riempio un'ora in più per lasciare un'ora di gioco libera fra due task successivi
                    index = index + t.duration + 1
                    assigned[day] = assigned[day] + 1
                    count = count + 1
                    break

                index = index + 1

                while week_table[index]:
                    index = index + 1
        
        if count < len(pending):
            continue

        new_cost = cost(fixed, pending)

        if new_cost < best_cost:
            best_cost = new_cost
            best = copy.deepcopy(pending)

        i = i + 1

    cost(fixed, best, True)

    result = fixed + best

    result.sort(key=sort_key)
    
    return result
        


def main():
    week_days = ['lunedì', 'martedì', 'mercoledì', 'giovedì', 'venerdì', 'sabato', 'domenica']

    goals = [
        Goal('Nuoto', 3, 2, 'SPORT'),
        Goal('Preparazione esami', 4, 1, 'EDUCAZIONE'),
        Goal('Pugilato', 3, 1, 'ALTRO')
    ]

    fixed = [
        Task('Reti di calcolatori', 3, 0, 8, 12),
        Task('Teoria dei segnali', 3, 0, 12, 15),
        Task('Innovazione', 1, 0, 15, 16),
        Task('Elettronica', 1, 1, 11, 13),
        Task('Teoria dei segnali', 3, 1, 13, 16),
        Task('Sistemi operativi', 3, 2, 8, 12),
        Task('Elettronica', 1, 2, 12, 13),
        Task('Reti di calcolatori', 1, 3, 13, 16),
        Task('Elettronica', 5, 3, 8, 13),
        Task('Innovazione', 3, 3, 16, 19),
        Task('Reti di calcolatori', 3, 4, 10, 13),
        Task('Elettronica', 2, 4, 14, 16),
        Task('Sistemi operativi', 2, 4, 16, 18)
    ]

    timetable = schedule(fixed, goals)

    for t in timetable:
        print(f'[{t.name}] {week_days[t.weekday]} {t.start}:00 -> {t.end}:00')


main()